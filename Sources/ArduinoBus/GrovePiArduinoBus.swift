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

public extension GrovePiBus {
  public static func connectBus() throws -> GrovePiBus {
    return try GrovePiArduinoBus.connectBus()
  }
}

private final class GrovePiArduinoBus: GrovePiBus {
  private static var bus: GrovePiArduinoBus? = nil
  let busNumber: UInt8 = 1
  let criticalSection: Lock = Lock()
  var fd: Int32 = -1
  var r_buf = [UInt8](repeating: 0, count: 32)
  var w_buf = [UInt8](repeating: 0, count: 4)

  private var portMap: [PortLabelWrapper : GrovePiIOUnit] = [:]

  static func connectBus() throws -> GrovePiBus {
    if bus == nil {
      bus = try GrovePiArduinoBus()
    }
    return bus!
  }

    init() throws {
//      self.access = GrovePiBusAccess()
      try openIO()
    }

  func connect<IP : GrovePiInputProtocol>(inputUnit: GrovePiInputUnit, to portLabel: GrovePiPortLabel, using inputProtocol: IP) throws -> AnyGrovePiInputSource<IP.InputValue> {
    let wrapper = PortLabelWrapper(portLabel)
    guard let _ = portMap[wrapper] else {
      throw GrovePiError.AlreadyOccupiedPort(portDescription: portLabel.description)
    }
    guard inputUnit.supportedPortTypes.contains(portLabel.type) else {
      throw GrovePiError.UnsupportedPortTypeForUnit(unitDescription: inputUnit.description, portTypeDescription: portLabel.type.description)
    }
    portMap[wrapper] = inputUnit
    return AnyGrovePiInputSource(try ArduinoInputSource(arduinoBus: self, portLabel: portLabel, inputProtocol: inputProtocol))
  }
  
  deinit {
    #if os(Linux)
      close(fd) // ignore any error
    #endif
  }
}

private struct PortLabelWrapper: Equatable, Hashable {
  let portLabel: GrovePiPortLabel
  var hashValue: Int { return portLabel.description.hashValue }

  init(_ portLabel: GrovePiPortLabel) {
    self.portLabel = portLabel
  }
  static func ==(lhs: PortLabelWrapper, rhs: PortLabelWrapper) -> Bool {
    return lhs.portLabel.type == rhs.portLabel.type && lhs.portLabel.id == rhs.portLabel.id
  }
}

private struct ArduinoInputSource<IP: GrovePiInputProtocol, InputValue: GrovePiInputValueType>: GrovePiInputSource where IP.InputValue == InputValue {
  let arduinoBus: GrovePiArduinoBus
  let portLabel: GrovePiPortLabel
  let inputProtocol: IP
  let inputChangeDelegates: MulticastDelegate<InputValueChangeDelegate, InputValue>
  let delayUSeconds: UInt32
  let extraParameters: [UInt8]

  public init(arduinoBus: GrovePiArduinoBus, portLabel: GrovePiPortLabel, inputProtocol: IP) throws {
    self.arduinoBus = arduinoBus
    self.portLabel = portLabel
    self.inputProtocol = inputProtocol
    inputChangeDelegates = MulticastDelegate()
    delayUSeconds = UInt32(inputProtocol.delayReadAfterRequestTimeInterval * 1_000_000)
    let extraBytes = inputProtocol.readCommandAdditionalParameters
    extraParameters = [extraBytes.count > 0 ? extraBytes[0] : 0, extraBytes.count > 1 ? extraBytes[1] : 0]
    try arduinoBus.setIOMode(.input, on: portLabel)
  }

  func readValue() throws -> InputValue {
    let valueBytes = try readBytes()
    return inputProtocol.convert(valueBytes: valueBytes)
  }

  private func readBytes() throws -> [UInt8] {
    return try arduinoBus.readCommand(command: inputProtocol.readCommand, portID: portLabel.id,
                                      parameter1: extraParameters[0], parameter2: extraParameters[1],
                                      delay: delayUSeconds, returnLength: inputProtocol.responseValueLength)
  }

}

// MARK: - the medium level of communication with the GrovePi

extension GrovePiArduinoBus {
  func readCommand(command: UInt8, portID: UInt8, parameter1: UInt8, parameter2: UInt8, delay: UInt32, returnLength: UInt8) throws -> [UInt8] {
    var bytes: [UInt8] = [0]
    try criticalSection.locked {
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

  func setIOMode(_ ioMode: IOMode, on portLabel: GrovePiPortLabel) throws {
    try criticalSection.locked {
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
        throw GrovePiError.OpenError(errno)
      }
      if ioctl(fd, UInt(I2C_SLAVE), 0x04/*Arduino*/) != 0 {
        throw GrovePiError.IOError(errno)
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
        throw GrovePiError.IOError(errno)
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
        throw GrovePiError.IOError(errno)
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
        throw GrovePiError.IOError(errno)
      }
    #endif
  }

}


