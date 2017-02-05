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
import Dispatch

internal final class GrovePiArduinoBus {
  private static var bus: GrovePiArduinoBus? = nil
  let arduinoAddress: UInt8 = 4
  let busNumber: UInt8 = 1
  fileprivate let serialBusLock: Lock = Lock()
  let retryCount = 9
  let delayBeforeRetryInMicroSeconds: UInt32 = 1_000
  var fd: Int32 = -1
  var nextReadCommandAfter = DispatchTime.now()


  private var portMap: [AnyGrovePiPortLabel : ConnectablePort]
  var scanner: GrovePiBusScanner

  lazy var firmwareVersion: String = {
    return (try? self.readFirmwareVersion()) ?? "?.?.?"
  }()

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
      if let existingInputSource = existingConnection as? ArduinoInputSource<PL,IU,IP>, existingInputSource.inputUnit == inputUnit {
        return AnyGrovePiInputSource(existingInputSource)
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
  
  public func connect<PL: GrovePiPortLabel, OU: GrovePiOutputUnit, OP: GrovePiOutputProtocol>(portLabel: PL, to outputUnit: OU,
                      using outputProtocol: OP) throws -> AnyGrovePiOutputDestination<PL, OU, OP.OutputValue> {
    let wrappedPortLabel = AnyGrovePiPortLabel(portLabel)
    if let existingConnection = portMap[wrappedPortLabel] {
      if let existingOutputDestination = existingConnection as? ArduinoOutputDestination<PL,OU,OP>, existingOutputDestination.outputUnit == outputUnit {
        return AnyGrovePiOutputDestination(existingOutputDestination)
      }
      throw GrovePiError.AlreadyOccupiedPort(portDescription: portLabel.description)
    }
    guard outputUnit.supportedPortTypes.contains(portLabel.type) else {
      throw GrovePiError.UnsupportedPortTypeForUnit(unitDescription: outputUnit.description, portTypeDescription: portLabel.type.description)
    }
    let outputSource = ArduinoOutputDestination(arduinoBus: self, portLabel: portLabel, outputUnit: outputUnit, outputProtocol: outputProtocol)
    try outputSource.connect()
    portMap[wrappedPortLabel] = outputSource
    return AnyGrovePiOutputDestination(outputSource)
  }
  
  public func disconnect<PL: GrovePiPortLabel>(from portLabel: PL) throws {
    if let connection = portMap.removeValue(forKey: AnyGrovePiPortLabel(portLabel)) {
      try connection.disconnect()
    }
  }

  private func readFirmwareVersion() throws -> String {
    let versionBytes = try readCommand(command: 8, portID: 0, parameter1: 0, parameter2: 0, gapBefore: 0, delay: 100_000, gapAfter: 0, returnLength: 3)
    guard versionBytes.count == 3 else { return "\(versionBytes)" }
    return "\(versionBytes[0]).\(versionBytes[1]).\(versionBytes[2])"
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


// MARK: - the medium level of communication with the GrovePi

extension GrovePiArduinoBus {
  func readCommand(command: UInt8, portID: UInt8, parameter1: UInt8, parameter2: UInt8, gapBefore: UInt32, delay: UInt32, gapAfter: UInt32, returnLength: UInt8) throws -> [UInt8] {
    let resultBytesCount = Int(UInt(returnLength))
    var bytes = [UInt8]()
    try serialBusLock.locked {
      try setAddress(arduinoAddress)
      var gapBeforeNext = nextReadCommandAfter.microsecondsFromNow()
      if gapBeforeNext <= 0 { gapBeforeNext += Int64(gapBefore) }
      if gapBeforeNext > 0 {
        usleep(UInt32(gapBeforeNext))
      }
      if GrovePiBus.printCommands { print("\(Date.hhmmssSSS) Read command=\(command)", "port=\(portID)", "par1=\(parameter1)", "par2=\(parameter2)", "gapBefore=\(gapBefore)", "delay=\(delay)", "gapAfter=\(gapAfter)", "returnLength=\(returnLength)", separator: ", ", terminator: "") }
      do {
        try writeBlock(command, portID, parameter1, parameter2)
        if (delay > 0) {
          usleep(delay) // without delay it may return zeroes the first time
        }
        let singleByte = try readByte()
        if returnLength > 1 {
          let readBytes = try readBlock()
          bytes = [UInt8](readBytes[1...resultBytesCount])
        } else {
          bytes = [singleByte]
        }
        nextReadCommandAfter = DispatchTime(microsecondsFromNow: gapAfter)
      } catch {
        if GrovePiBus.printCommands { print(" throws \(error)") }
        throw error
      }
      if GrovePiBus.printCommands { print(" -> \(bytes)") }
    }
    return bytes
  }

  func writeCommand(command: UInt8, portID: UInt8, valueBytes: [UInt8]) throws {
    let v0 = valueBytes.count > 0 ? valueBytes[0] : 0
    let v1 = valueBytes.count > 1 ? valueBytes[1] : 0
    try serialBusLock.locked {
      try setAddress(arduinoAddress)
      if GrovePiBus.printCommands { print("\(Date.hhmmssSSS) Write command=\(command)", "port=\(portID)", "val1=\(v0)", "val2=\(v1)", separator: ", ") }
      try writeBlock(command, portID, v0, v1)
    }
  }

  func otherWriteCommand<OutputValue>(value: OutputValue, closure: (OutputValue) throws -> ()) throws {
    try serialBusLock.locked {
      try closure(value)
    }
  }

  func setIOMode(portID: UInt8, _ ioModeValue: UInt8) throws {
    try serialBusLock.locked {
      try setAddress(arduinoAddress)
      if GrovePiBus.printCommands { print("\(Date.hhmmssSSS) Set I/O Mode", "port=\(portID)", "value=\(ioModeValue)", separator: ", ") }
      try writeBlock(5, portID, ioModeValue)
    }
  }

}

// MARK: - the lowest level of communication with the GrovePi

extension GrovePiArduinoBus {

  func openIO() throws {
    #if os(Linux)
      fd = open("/dev/i2c-\(busNumber)", O_RDWR)
    #else
      fd = 1
    #endif
    if fd < 0 {
      throw GrovePiError.OpenError(osError: errno)
    }
  }

  func closeIO() throws {
    guard fd >= 0 else { return }
    var result: Int32
    #if os(Linux)
      result = close(fd)
    #else
      result = fd >= 0 ? 1 : -1
    #endif
    fd = -1
    if result < 0 {
      throw GrovePiError.CloseError(osError: errno)
    }
  }

  func setAddress(_ address: UInt8) throws {
    #if os(Linux)
      if ioctl_address(fd, UInt(I2C_SLAVE), address) != 0 {
        throw GrovePiError.IOError(osError: errno)
      }
    #endif
  }

  func readByte() throws -> UInt8 {
    var result: Int32 = 0;
    for n in 0...retryCount {
      if n > 0 {
        usleep(delayBeforeRetryInMicroSeconds)
      }
      #if os(Linux)
        result = i2c_smbus_read_byte(fd)
      #else
        result = 1
      #endif
      if result >= 0 {
        break
      }
    }
    if result < 0 {
      throw GrovePiError.IOError(osError: errno)
    }
    return UInt8(result)
  }

  func readBlock() throws -> [UInt8] {
    var inBuffer = [UInt8](repeating: 0xFF, count: 32)
    var result: Int32 = 0;
    for n in 0...retryCount {
      if n > 0 {
        usleep(delayBeforeRetryInMicroSeconds)
      }
      #if os(Linux)
        result = i2c_smbus_read_i2c_block_data(fd, 1, UInt8(inBuffer.count), &inBuffer[0])
      #else
        result = 1
      #endif
      if result >= 0 {
        break
      }
    }
    if result < 0 {
      throw GrovePiError.IOError(osError: errno)
    }
    return inBuffer
  }

  func writeByte(_ cmd: UInt8, val: UInt8) throws {
    var result: Int32 = 0;
    for n in 0...retryCount {
      if n > 0 {
        usleep(delayBeforeRetryInMicroSeconds)
      }
      #if os(Linux)
        result = i2c_smbus_write_byte_data(fd, cmd, val)
      #else
        result = 1
      #endif
      if result >= 0 {
        break
      }
    }
    if (result < 0) {
      throw GrovePiError.IOError(osError: errno)
    }
  }

  func writeBlock(_ cmd: UInt8, _ v1: UInt8, _ v2: UInt8 = 0, _ v3: UInt8 = 0) throws {
    var outBuffer = [UInt8](repeating: 0, count: 4)
    outBuffer[0] = cmd; outBuffer[1] = v1; outBuffer[2] = v2; outBuffer[3] = v3
    var result: Int32 = 0;
    for n in 0...retryCount {
      if n > 0 {
        usleep(delayBeforeRetryInMicroSeconds)
      }
      #if os(Linux)
        result = i2c_smbus_write_i2c_block_data(fd, 1, UInt8(outBuffer.count), outBuffer)
      #else
        result = 1
      #endif
      if result >= 0 {
        break
      }
    }
    if (result < 0) {
      throw GrovePiError.IOError(osError: errno)
    }
  }

}


