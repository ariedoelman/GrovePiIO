//
//  GrovePiArduinoBus.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 15-01-17.
//
//

#if os(Linux)
  import Glibc
  import CGrovepi
#else
  import Darwin.C
#endif
import Foundation

internal protocol GrovePiInputProtocol {
  associatedtype InputValue: GrovePiInputValueType

  var readCommand: UInt8 { get }
  var readCommandAdditionalParameters: [UInt8] { get }
  var delayReadAfterCommandTimeInterval: TimeInterval { get }
  var responseValueLength: UInt8 { get }

  func convert(valueBytes: [UInt8]) -> InputValue
  func areSignificantDifferent(newValue: InputValue, previousValue: InputValue) -> Bool
}

internal extension GrovePiInputProtocol {
  var delayReadAfterCommandTimeInterval: TimeInterval { return 0.025 } // default delay of 25 ms
}

internal final class GrovePiArduinoBus {
  private static var bus: GrovePiArduinoBus? = nil
  let busNumber: UInt8 = 1
  let serialBusLock: Lock = Lock()
  var fd: Int32 = -1
  var r_buf = [UInt8](repeating: 0, count: 32)
  var w_buf = [UInt8](repeating: 0, count: 4)

  private var portMap: [AnyGrovePiPortLabel : ConnectablePort]
  var scanner: GrovePiBusScanner

  public static func connectBus() throws -> GrovePiArduinoBus {
    if bus == nil {
      bus = try GrovePiArduinoBus()
    }
    return bus!
  }

  public static func disconnectBus() throws {
    guard bus != nil else { return }
    defer { bus = nil }
    try bus!.disconnect()
  }

  private init() throws {
    portMap = [:]
    scanner = GrovePiBusScanner()
    try openIO()
  }

  public func connect<PL: GrovePiPortLabel, IU: GrovePiInputUnit, IP: GrovePiInputProtocol>(portLabel: PL, to inputUnit: IU,
  using inputProtocol: IP) throws -> AnyGrovePiInputSource<PL, IU, IP.InputValue> {
    let wrappedPortLabel = AnyGrovePiPortLabel(portLabel)
    if let existingConnection = portMap[wrappedPortLabel] {
      if let existingInputSource = existingConnection as? ArduinoInputSource<PL,IU,IP>, existingInputSource.portLabel == portLabel {

      }
      throw GrovePiError.AlreadyOccupiedPort(portDescription: portLabel.description)
    }
    guard inputUnit.supportedPortTypes.contains(portLabel.type) else {
      throw GrovePiError.UnsupportedPortTypeForUnit(unitDescription: inputUnit.description, portTypeDescription: portLabel.type.description)
    }
    let inputSource = ArduinoInputSource(arduinoBus: self, portLabel: portLabel, inputUnit: inputUnit, inputProtocol: inputProtocol)
    try inputSource.connect()
    portMap[wrappedPortLabel] = inputSource
    return AnyGrovePiInputSource(inputSource)
  }

  public func disconnect<PL: GrovePiPortLabel>(from portLabel: PL) throws {
    if let connection = portMap.removeValue(forKey: AnyGrovePiPortLabel(portLabel)) {
      try connection.disconnect()
    }
  }

  private func disconnect() throws {
    while let (port, connection) = portMap.first {
      try? connection.disconnect()  // ignore errors on port by port basis
      portMap.removeValue(forKey: port)
    }
    try closeIO()
  }
  
  deinit {
    #if os(Linux)
      try? closeIO() // ignore any error
    #endif
  }
}

private final class ArduinoInputSource<PL: GrovePiPortLabel, IU: GrovePiInputUnit, IP: GrovePiInputProtocol>: GrovePiInputSource {
  fileprivate weak var arduinoBus: GrovePiArduinoBus?
  let portLabel: PL
  let inputUnit: IU
  let inputProtocol: IP
  let inputChangedDelegates: MulticastDelegate<AnyInputValueChangedDelegate<IP.InputValue>, IP.InputValue>
  let delayUSeconds: UInt32
  let extraParameters: [UInt8]
  var lastChangedValue: IP.InputValue?
  var isConnected: Bool
  var delegatesCount: Int { return inputChangedDelegates.count }

  fileprivate init(arduinoBus: GrovePiArduinoBus, portLabel: PL, inputUnit: IU, inputProtocol: IP) {
    self.arduinoBus = arduinoBus
    self.portLabel = portLabel
    self.inputUnit = inputUnit
    self.inputProtocol = inputProtocol
    inputChangedDelegates = MulticastDelegate()
    delayUSeconds = inputProtocol.delayReadAfterCommandTimeInterval.uSeconds
    let extraBytes = inputProtocol.readCommandAdditionalParameters
    extraParameters = [extraBytes.count > 0 ? extraBytes[0] : 0, extraBytes.count > 1 ? extraBytes[1] : 0]
    isConnected = false
  }

  func readValue() throws -> IP.InputValue {
    guard let _ = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard isConnected else { throw GrovePiError.DisconnectedPort(portDescription: portLabel.description) }
    let valueBytes = try readBytes()
    return inputProtocol.convert(valueBytes: valueBytes)
  }

  func addValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == IP.InputValue*/ {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard isConnected else { throw GrovePiError.DisconnectedPort(portDescription: portLabel.description) }
    inputChangedDelegates.addDelegate(AnyInputValueChangedDelegate(delegate))
    if inputChangedDelegates.count == 1 {
      arduinoBus.scanner.addScanItem(portLabel: portLabel, sampleTimeInterval: inputUnit.sampleTimeInterval, evaluation: valueChangedEvaluation)
    }
  }

  func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == IP.InputValue*/ {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard isConnected else { throw GrovePiError.DisconnectedPort(portDescription: portLabel.description) }
    inputChangedDelegates.removeDelegate(AnyInputValueChangedDelegate(delegate))
    if inputChangedDelegates.count == 0 {
      arduinoBus.scanner.removeScanItem(portLabel: portLabel)
    }
  }

  func connect() throws {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard !isConnected else { return } // no problem to connect more than once
    isConnected = true
    try arduinoBus.setIOMode(.input, on: portLabel)

  }

  func disconnect() throws {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard isConnected else { return } // no problem to disconnect more than once
    isConnected = false
    if inputChangedDelegates.count > 0 {
      inputChangedDelegates.removeAllDelegates()
      arduinoBus.scanner.removeScanItem(portLabel: portLabel)
    }
  }

  static func ==(lhs: ArduinoInputSource, rhs: ArduinoInputSource) -> Bool {
    return lhs.portLabel == rhs.portLabel && lhs.inputUnit == rhs.inputUnit
  }

  private func valueChangedEvaluation(timeIntervalSinceReferenceDate: TimeInterval) throws {
    let newValue = try readValue()
    let previousValue = lastChangedValue
    if previousValue == nil || inputProtocol.areSignificantDifferent(newValue: newValue, previousValue: previousValue!) {
      inputChangedDelegates.invoke(parameter: newValue, invocation: { $0.newInputValue($1, timeIntervalSinceReferenceDate) })
      lastChangedValue = newValue
    }
  }

  private func readBytes() throws -> [UInt8] {
    guard let arduinoBus = self.arduinoBus else {
      throw GrovePiError.DisconnectedBus
    }
    return try arduinoBus.readCommand(command: inputProtocol.readCommand, portID: portLabel.id,
                                      parameter1: extraParameters[0], parameter2: extraParameters[1],
                                      delay: delayUSeconds, returnLength: inputProtocol.responseValueLength)
  }

}

// MARK: - the medium level of communication with the GrovePi

extension GrovePiArduinoBus {
  func readCommand(command: UInt8, portID: UInt8, parameter1: UInt8, parameter2: UInt8, delay: UInt32, returnLength: UInt8) throws -> [UInt8] {
    var bytes: [UInt8] = [0]
    try serialBusLock.locked {
      try writeBlock(command, portID, parameter1, parameter2)
      if (delay > 0) {
        usleep(delay) // without delay always returns zeroes the first time
      }
      bytes[0] = try readByte()
      if returnLength > 1 {
        bytes = try readBlock()
      }
    }
    if returnLength == 1 {
      return bytes
    }
    return [UInt8](bytes[1...Int(returnLength)])
  }

  func setIOMode<PL: GrovePiPortLabel>(_ ioMode: IOMode, on portLabel: PL) throws {
    try serialBusLock.locked {
      try writeBlock(5, portLabel.id, ioMode.rawValue)
    }
  }

}

// MARK: - the lowest level of communication with the GrovePi

extension GrovePiArduinoBus {

  func openIO() throws {
    #if os(Linux)
      fd = open("/dev/i2c-\(busNumber)", O_RDWR)
      if fd < 0 {
        throw GrovePiError.OpenError(osError: GrovePiError.fromErrno())
      }
      if ioctl(fd, UInt(I2C_SLAVE), 0x04/*Arduino*/) != 0 {
        throw GrovePiError.IOError(osError: GrovePiError.fromErrno())
      }
    #endif
  }

  func closeIO() throws {
    guard fd >= 0 else { return }
    #if os(Linux)
      let result = close(fd)
      fd = -1
      if result < 0 {
        throw GrovePiError.CloseError(osError: GrovePiError.fromErrno())
      }
    #endif
  }

  func readByte() throws -> UInt8 {
    #if os(Linux)
      var result: Int32 = 0;
      for _ in 0...retryCount {
        r_buf[0] = 0
        result = i2c_smbus_read_byte(fd)
        if result >= 0 {
          break
        }
        usleep(delayBeforeRetryInMicroSeconds)
      }
      if result < 0 {
        throw GrovePiError.IOError(osError: GrovePiError.fromErrno())
      }
      r_buf[0] = UInt8(result)
      return UInt8(result)
    #else
      return 0
    #endif
  }

  func readBlock() throws -> [UInt8] {
    #if os(Linux)
      var result: Int32 = 0;
      for _ in 0...retryCount {
        for i in 1..<r_buf.count { r_buf[i] = 0 }
        result = i2c_smbus_read_i2c_block_data(fd, 1, UInt8(r_buf.count), &r_buf[0])
        if result >= 0 {
          break
        }
        usleep(delayBeforeRetryInMicroSeconds)
      }
      if result < 0 {
        throw GrovePiError.IOError(osError: GrovePiError.fromErrno())
      }
      return r_buf
    #else
      return [UInt8](repeating: 0, count: 32)
    #endif
  }

  func writeBlock(_ cmd: UInt8, _ v1: UInt8, _ v2: UInt8 = 0, _ v3: UInt8 = 0) throws {
    #if os(Linux)
      w_buf[0] = cmd; w_buf[1] = v1; w_buf[2] = v2; w_buf[3] = v3
      var result: Int32 = 0;
      for _ in 0...retryCount {
        result = i2c_smbus_write_i2c_block_data(fd, 1, UInt8(w_buf.count), w_buf)
        if result >= 0 {
          break
        }
        usleep(delayBeforeRetryInMicroSeconds)
      }
      if (result < 0) {
        throw GrovePiError.IOError(osError: GrovePiError.fromErrno())
      }
    #endif
  }

}


