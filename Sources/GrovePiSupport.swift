//
//  GrovePiIO.swift
//  hello-persistence
//
//  Created by Arie Doelman on 29-12-16.
//
//

#if os(Linux)
  import Glibc
  import CGrovepi
#else
  import Darwin.C
#endif

final class GrovePiArduinoBus1: GrovePiBus {
  public var retryCount: UInt8 = 9 // Following the example of GrovePi Python implementation
  public var delayBeforeRetryInMicroSeconds: UInt32 = 1_000
  fileprivate static var bus: GrovePiBus? = nil
  fileprivate var fd: Int32 = -1
  fileprivate var r_buf = [UInt8](repeating: 0, count: 32)
  fileprivate var w_buf = [UInt8](repeating: 0, count: 4)

  static func getBus() throws -> GrovePiBus {
    if bus == nil {
      bus = try GrovePiArduinoBus1()
    }
    return bus!
  }

  func temperatureAndHumiditySensor(at port: GrovePiPort, moduleType: DHTModuleType) throws -> TemperatureAndHumiditySensor {
    return try ATemperatureAndHumiditySensor(bus: self, port: port, moduleType: moduleType)
  }

  func ultrasonicRangeSensor(at port: GrovePiPort) throws -> UltrasonicRangeSensor {
    return try AUltrasonicRangeSensor(bus: self, port: port)
  }

  func ledLight(at port: GrovePiPort, color: LEDColor) throws -> LEDLight {
    return try ALEDLight(bus: self, port: port, color: color)
  }

  func lightSensor(at port: GrovePiPort) throws -> LightSensor {
    return try ALightSensor(bus: self, port: port)
  }

  func momentaryOnOffButton(at port: GrovePiPort) throws -> MomentaryOnOffButton {
    return try AMomentaryOnOffButton(bus: self, port: port)
  }

  func potentioMeter(at port: GrovePiPort) throws -> PotentioMeter {
    return try APotentioMeter(bus: self, port: port)
  }

  init() throws {
    try openIO()
  }

  deinit {
    #if os(Linux)
      close(fd) // ignore any error
    #endif
  }

}

fileprivate class GrovePiArduinoIO: GrovePiIO {
  var bus: GrovePiBus { return bus1 }
  fileprivate var bus1: GrovePiArduinoBus1
  fileprivate(set) var port: GrovePiPort

  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort, ioMode: IOMode) throws {
    self.bus1 = bus
    self.port = port
    try doSetIOMode(to: ioMode)
  }

  fileprivate func readAnalogueValue() throws -> UInt16 {
    return try doReadAnalogueValue()
  }

  fileprivate func readUltrasonicRange() throws -> UInt16 {
    return try doReadUltraSonicRange()
  }

  fileprivate func readDigitalValue() throws -> DigitalValue {
    return try doReadDigitalValue()
  }

  fileprivate func readTemperatureAndHumidity(moduleType: DHTModuleType) throws -> (temperature: Float, humidity: Float) {
    return try doReadTemperatureAndHumidity(moduleType: moduleType)
  }

  fileprivate func setDigitalValue(_ digitalValue: DigitalValue) throws {
    try doWriteDigitalValue(digitalValue)
  }

  fileprivate func setAnalogueValue(_ value: UInt8) throws {
    try doWriteAnalogueValue(value)
  }
}

fileprivate final class ATemperatureAndHumiditySensor: GrovePiArduinoIO, TemperatureAndHumiditySensor {
  let moduleType: DHTModuleType

  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort, moduleType: DHTModuleType) throws {
    self.moduleType = moduleType
    try super.init(bus: bus, port: port, ioMode: .input)
  }

  func readTH() throws -> (temperature: Float, humidity: Float) {
    return try readTemperatureAndHumidity(moduleType: moduleType)
  }

}

fileprivate final class ALightSensor: GrovePiArduinoIO, LightSensor {
  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
    try super.init(bus: bus, port: port, ioMode: .input)
  }

  func readIntensity() throws -> UInt16 {
    return try readAnalogueValue()
  }
}


fileprivate final class AUltrasonicRangeSensor: GrovePiArduinoIO, UltrasonicRangeSensor {
  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
    try super.init(bus: bus, port: port, ioMode: .input)
  }

  func readCentimeters() throws -> UInt16 {
    return try readAnalogueValue()
  }
}

fileprivate final class ALEDLight: GrovePiArduinoIO, LEDLight {
  let color: LEDColor

  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort, color: LEDColor) throws {
    self.color = color
    try super.init(bus: bus, port: port, ioMode: .output)
  }

  func setValue(_ digitalValue: DigitalValue) throws {
    try setDigitalValue(digitalValue)
  }

  func setValue(_ value: UInt8) throws {
    try setAnalogueValue(value)
  }
}

fileprivate final class AMomentaryOnOffButton: GrovePiArduinoIO, MomentaryOnOffButton {
  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
    try super.init(bus: bus, port: port, ioMode: .input)
  }

  func readState() throws -> DigitalValue {
    return try readDigitalValue()
  }
}

fileprivate final class APotentioMeter: GrovePiArduinoIO, PotentioMeter {
  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
    try super.init(bus: bus, port: port, ioMode: .input)
  }

  func readValue() throws -> UInt16 {
    return try readAnalogueValue()
  }
}

extension GrovePiArduinoIO {
  private enum Command: UInt8 {
    case digitalRead = 1
    case digitalWrite = 2
    case analogRead = 3
    case analogWrite = 4
    case pinMode = 5
    case ultrasonicRangeRead = 7
    case temperatureAndHumidityRead = 40
  }

  // MARK: - private implementation details

  fileprivate func doSetIOMode(to ioMode: IOMode) throws {
    try bus1.writeBlock(Command.pinMode.rawValue, port.id, ioMode.rawValue)
  }

  fileprivate func doReadAnalogueValue() throws -> UInt16 {
    try bus1.writeBlock(Command.analogRead.rawValue, port.id)
    _ = try bus1.readByte()
    let bytes = try bus1.readBlock()
    return (UInt16(bytes[1]) << 8) | UInt16(bytes[2])
  }

  fileprivate func doReadDigitalValue() throws -> DigitalValue {
    try bus1.writeBlock(Command.digitalRead.rawValue, port.id)
    let byte = try bus1.readByte()
    return byte == 0 ? .low : .high
  }

  fileprivate func doReadTemperatureAndHumidity(moduleType: DHTModuleType) throws -> (temperature: Float, humidity: Float) {
    try bus1.writeBlock(Command.temperatureAndHumidityRead.rawValue, port.id, moduleType.rawValue)
    _ = try bus1.readByte()
    let bytes = try bus1.readBlock()
    var temperature = Float(ieee754LittleEndianBytes: bytes, offset: 1)
    if !(temperature > -100.0 && temperature < 150.0) {
      temperature = .nan
    }
    var humidity = Float(ieee754LittleEndianBytes: bytes, offset: 5)
    if !(humidity >= 0.0 && humidity <= 100.0) {
      humidity = .nan
    }
    return (temperature, humidity)
  }

  fileprivate func doReadUltraSonicRange() throws -> UInt16 {
    try bus1.writeBlock(Command.ultrasonicRangeRead.rawValue, port.id)
    usleep(51_000) // firmware has a time of 50ms so wait for more than that
    _ = try bus1.readByte()
    let bytes = try bus1.readBlock()
    return (UInt16(bytes[1]) << 8) | UInt16(bytes[2])
  }

  fileprivate func doWriteAnalogueValue(_ value: UInt8) throws {
    try bus1.writeBlock(Command.analogWrite.rawValue, port.id, value)
  }

  fileprivate func doWriteDigitalValue(_ value: DigitalValue) throws {
    try bus1.writeBlock(Command.digitalWrite.rawValue, port.id, value.rawValue)
  }

  fileprivate func doWriteAnalogueValue(to value: UInt8) throws {
    try bus1.writeBlock(Command.digitalWrite.rawValue, port.id, value)
  }

}

extension GrovePiArduinoBus1 {
  // MARK: - private GrovePiBus implementation

  fileprivate func openIO() throws {
    #if os(Linux)
      fd = open("/dev/i2c-1", O_RDWR) // bus number 1
      if fd < 0 {
        throw GrovePiError.OpenError(errno)
      }
      if ioctl(fd, UInt(I2C_SLAVE), 0x04/*Arduino*/) != 0 {
        throw GrovePiError.IOError(errno)
      }
    #endif
  }

  fileprivate func readByte() throws -> UInt8 {
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

  fileprivate func readBlock() throws -> [UInt8] {
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
      return []
    #endif
  }

  fileprivate func writeBlock(_ cmd: UInt8, _ v1: UInt8, _ v2: UInt8 = 0, _ v3: UInt8 = 0) throws {
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

fileprivate extension Float {
  init(ieee754LittleEndianBytes fbs: [UInt8], offset i: Int) {
    self.init(bitPattern: (UInt32(fbs[i+3]) << 24) | (UInt32(fbs[i+2]) << 16) | (UInt32(fbs[i+1]) << 8) | UInt32(fbs[i]))
  }
}




