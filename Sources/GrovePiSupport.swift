////
////  GrovePiIO.swift
////  GrovePiIO
////
////  Created by Arie Doelman on 29-12-16.
////
////
//
//#if os(Linux)
//  import Glibc
//  import CGrovepi
//#else
//  import Darwin.C
//#endif
//import Foundation
//
//private struct PortLabelWrapper: Equatable, Hashable {
//  let portLabel: GrovePiPortLabel
//  var hashValue: Int { return portLabel.description.hashValue }
//
//  init(_ portLabel: GrovePiPortLabel) {
//    self.portLabel = portLabel
//  }
//  static func ==(lhs: PortLabelWrapper, rhs: PortLabelWrapper) -> Bool {
//    return lhs.portLabel.type == rhs.portLabel.type && lhs.portLabel.id == rhs.portLabel.id
//  }
//}
//
//internal final class GrovePiArduinoBus1: GrovePiBus {
//  var retryCount: UInt8 = 9 // Following the example of GrovePi Python implementation
//  var delayBeforeRetryInMicroSeconds: UInt32 = 1_000
//  fileprivate let access: GrovePiBusAccess
//  private static var bus: GrovePiArduinoBus1? = nil
//  fileprivate var fd: Int32 = -1
//  fileprivate var r_buf = [UInt8](repeating: 0, count: 32)
//  fileprivate var w_buf = [UInt8](repeating: 0, count: 4)
//  fileprivate let criticalSection: Lock = Lock()
//
//  private var portMap: [PortLabelWrapper : GrovePiIOUnit] = [:]
//
//  static func getBus() throws -> GrovePiBus {
//    if bus == nil {
//      bus = try GrovePiArduinoBus1()
//    }
//    return bus!
//  }
//
//  func connect<IU: GrovePiInputUnit, IP: GrovePiInputProtocol>(inputUnit: IU, to portLabel: GrovePiPortLabel,
//               using inputProtocol: IP) throws -> AnyGrovePiInputConnection<IU, IP> {
//    let wrapper = PortLabelWrapper(portLabel)
//    guard let _ = portMap[wrapper] else {
//      throw GrovePiError.AlreadyOccupiedPort(portDescription: portLabel.description)
//    }
//    guard inputUnit.supportedPortTypes.contains(portLabel.type) else {
//      throw GrovePiError.UnsupportedPortTypeForUnit(unitDescription: inputUnit.description, portTypeDescription: portLabel.type.description)
//    }
//    portMap[wrapper] = inputUnit
//  }
//
//  func disconnect(from portLabel: GrovePiPortLabel) throws {
//
//  }
//
////  func temperatureAndHumiditySensor(at port: GrovePiDigitalPort, moduleType: DHTModuleType) throws -> TemperatureAndHumiditySensor {
////    return try ATemperatureAndHumiditySensor(bus: self, port: port, moduleType: moduleType)
////  }
////
////  func ultrasonicRangeSensor(at port: GrovePiDigitalPort) throws -> UltrasonicRangeSensor {
////    return try AUltrasonicRangeSensor(bus: self, port: port)
////  }
////
////  func ledLight(at port: GrovePiDigitalPort, color: LEDColor) throws -> LEDLight {
////    return try ALEDLight(bus: self, port: port, color: color)
////  }
////
////  func lightSensor(at port: GrovePiAnaloguePort) throws -> LightSensor {
////    return try ALightSensor(bus: self, port: port)
////  }
////
////  func momentaryOnOffButton(at port: GrovePiDigitalPort) throws -> MomentaryOnOffButton {
////    return try AMomentaryOnOffButton(bus: self, port: port)
////  }
////
////  func potentioMeter(at port: GrovePiAnaloguePort) throws -> PotentioMeter {
////    return try APotentioMeter(bus: self, port: port)
////  }
//
//  init() throws {
//    self.access = GrovePiBusAccess()
//    try openIO()
//  }
//
//  deinit {
//    #if os(Linux)
//      close(fd) // ignore any error
//    #endif
//  }
//
//}
//
//fileprivate class GrovePiArduinoIO: GrovePiIO {
//  var bus: GrovePiBus { return bus1 }
//  fileprivate var bus1: GrovePiArduinoBus1
//  fileprivate(set) var port: GrovePiPort
//
//  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort, ioMode: IOMode) throws {
//    self.bus1 = bus
//    self.port = port
//    try directSetIOMode(to: ioMode)
//  }
//
//  fileprivate func readAnalogueValue() throws -> UInt16 {
//    return try directReadAnalogueValue()
//  }
//
////  fileprivate func readUltrasonicRange() throws -> UInt16 {
////    return try directReadUltraSonicRange()
////  }
////
//  fileprivate func readDigitalValue() throws -> DigitalValue {
//    return try directReadDigitalValue()
//  }
//
////  fileprivate func readTemperatureAndHumidity(moduleType: DHTModuleType) throws -> (temperature: Float, humidity: Float) {
////    return try directReadTemperatureAndHumidity(moduleType: moduleType)
////  }
////
//  fileprivate func setDigitalValue(_ digitalValue: DigitalValue) throws {
//    try directWriteDigitalValue(digitalValue)
//  }
//
//  fileprivate func setAnalogueValue(_ value: UInt8) throws {
//    try directWriteAnalogueValue(value)
//  }
//
////  func cancelChangeReport(withID reportID: ChangeReportID) {
////    bus1.access.removeSensorScan(withID: reportID, from: self)
////  }
//
////  fileprivate func cancelAllChangeReports() {
////    bus1.access.removeAllSensorScan(from: self)
////  }
//
//}
//
////fileprivate final class ATemperatureAndHumiditySensor: GrovePiArduinoIO, TemperatureAndHumiditySensor {
////  let moduleType: DHTModuleType
////
////  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort, moduleType: DHTModuleType) throws {
////    self.moduleType = moduleType
////    try super.init(bus: bus, port: port, ioMode: .input)
////  }
////
////  func readTemperatureAndHumidity() throws -> (temperature: Float, humidity: Float) {
////    return try readTemperatureAndHumidity(moduleType: moduleType)
////  }
////
////  func onChange(report: @escaping (_ temperature: Float, _ humidity: Float) -> ()) -> ChangeReportID {
////    let areDifferent: ((Float, Float), (Float, Float)) -> (Bool) = { value1,value2 in
////      if value1.0.isNaN {
////        if !value2.0.isNaN {
////          return true
////        }
////      } else if value2.0.isNaN || abs(value1.0 - value2.0) >= 1.0 {
////        return true
////      }
////      if value1.1.isNaN {
////        if !value2.1.isNaN {
////          return true
////        }
////      } else if value2.1.isNaN || abs(value1.1 - value2.1) >= 1.0 {
////        return true
////      }
////      return false
////    }
////    return bus1.access.addTwoFloatsSensorScan(at: self, readInput: directReadTemperatureAndHumidity,
////                                                ifChanged: areDifferent, reportChange: report)
////  }
////
////  private func directReadTemperatureAndHumidity() throws -> (temperature: Float, humidity: Float) {
////    return try directReadTemperatureAndHumidity(moduleType: moduleType)
////  }
////
////}
//
////fileprivate final class ALightSensor: GrovePiArduinoIO, LightSensor {
////  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
////    try super.init(bus: bus, port: port, ioMode: .input)
////  }
////
////  func readIntensity() throws -> UInt16 {
////    return try readAnalogueValue()
////  }
////
////  fileprivate func onChange(report: @escaping (UInt16) -> ()) -> ChangeReportID {
////    let areDifferent: (UInt16, UInt16) -> (Bool) = { value1, value2 in abs(Int16(value1) - Int16(value2)) >= 2 }
////    return bus1.access.addAnalogueSensorScan(at: self, readInput: directReadAnalogueValue, ifChanged: areDifferent, reportChange: report)
////  }
////}
////
////
////fileprivate final class AUltrasonicRangeSensor: GrovePiArduinoIO, UltrasonicRangeSensor {
////  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
////    try super.init(bus: bus, port: port, ioMode: .input)
////  }
////
////  func readCentimeters() throws -> UInt16 {
////    return try readAnalogueValue()
////  }
////
////  fileprivate func onChange(report: @escaping (UInt16) -> ()) -> ChangeReportID {
////    let areDifferent: (UInt16, UInt16) -> (Bool) = { value1, value2 in abs(Int16(value1) - Int16(value2)) >= 2 }
////    return bus1.access.addAnalogueSensorScan(at: self, readInput: directReadAnalogueValue, ifChanged: areDifferent, reportChange: report)
////  }
////}
////
////fileprivate final class ALEDLight: GrovePiArduinoIO, LEDLight {
////  let color: LEDColor
////
////  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort, color: LEDColor) throws {
////    self.color = color
////    try super.init(bus: bus, port: port, ioMode: .output)
////  }
////
////  func setValue(_ digitalValue: DigitalValue) throws {
////    try setDigitalValue(digitalValue)
////  }
////
////  func setValue(_ value: UInt8) throws {
////    try setAnalogueValue(value)
////  }
////}
////
////fileprivate final class AMomentaryOnOffButton: GrovePiArduinoIO, MomentaryOnOffButton {
////  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
////    try super.init(bus: bus, port: port, ioMode: .input)
////  }
////
////  func readState() throws -> DigitalValue {
////    return try readDigitalValue()
////  }
////
////  fileprivate func onChange(report: @escaping (DigitalValue) -> ()) -> ChangeReportID {
////    let areDifferent: (DigitalValue, DigitalValue) -> (Bool) = { value1, value2 in value1.rawValue != value2.rawValue }
////    return bus1.access.addDigitalSensorScan(at: self, readInput: directReadDigitalValue, ifChanged: areDifferent, reportChange: report)
////  }
////}
////
////fileprivate final class APotentioMeter: GrovePiArduinoIO, PotentioMeter {
////  fileprivate init(bus: GrovePiArduinoBus1, port: GrovePiPort) throws {
////    try super.init(bus: bus, port: port, ioMode: .input)
////  }
////
////  func readValue() throws -> UInt16 {
////    return try readAnalogueValue()
////  }
////
////  fileprivate func onChange(report: @escaping (UInt16) -> ()) -> ChangeReportID {
////    let areDifferent: (UInt16, UInt16) -> (Bool) = { value1, value2 in abs(Int16(value1) - Int16(value2)) >= 2 }
////    return bus1.access.addAnalogueSensorScan(at: self, readInput: directReadAnalogueValue, ifChanged: areDifferent, reportChange: report)
////  }
////}
//
//extension GrovePiArduinoIO {
//  private enum Command: UInt8 {
//    case digitalRead = 1
//    case digitalWrite = 2
//    case analogRead = 3
//    case analogWrite = 4
//    case pinMode = 5
//    case ultrasonicRangeRead = 7
//    case temperatureAndHumidityRead = 40
//  }
//
//  // MARK: - private implementation details
//
//  fileprivate func directSetIOMode(to ioMode: IOMode) throws {
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.pinMode.rawValue, port.id, ioMode.rawValue)
//    }
//  }
//
//  fileprivate func directReadAnalogueValue() throws -> UInt16 {
//    var bytes: [UInt8] = []
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.analogRead.rawValue, port.id)
//      usleep(25_000) // without delay always returns zeroes the first time
//      _ = try bus1.readByte()
//      bytes = try bus1.readBlock()
//    }
//    return (UInt16(bytes[1]) << 8) | UInt16(bytes[2])
//  }
//
//  fileprivate func directReadDigitalValue() throws -> DigitalValue {
//    var byte: UInt8 = 0
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.digitalRead.rawValue, port.id)
//      usleep(25_000) // without delay always returns zeroes the first time
//      byte = try bus1.readByte()
//    }
//    return byte == 0 ? .low : .high
//  }
//
//  fileprivate func directReadTemperatureAndHumidity(moduleType: DHTModuleType) throws -> (temperature: Float, humidity: Float) {
//    var bytes: [UInt8] = []
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.temperatureAndHumidityRead.rawValue, port.id, moduleType.rawValue)
//      usleep(25_000) // without delay always returns zeroes the first time
//      _ = try bus1.readByte()
//      bytes = try bus1.readBlock()
//    }
//    var temperature = Float(ieee754LittleEndianBytes: bytes, offset: 1)
//    if temperature > -100.0 && temperature < 150.0 {
//      temperature = (temperature * 10.0).rounded() / 10.0
//    } else {
//      temperature = .nan
//    }
//    var humidity = Float(ieee754LittleEndianBytes: bytes, offset: 5)
//    if humidity >= 0.0 && humidity <= 100.0 {
//      humidity = (humidity * 10.0).rounded() / 10.0
//    } else {
//      humidity = .nan
//    }
//    return (temperature, humidity)
//  }
//
//  fileprivate func directReadUltraSonicRange() throws -> UInt16 {
//    var bytes: [UInt8] = []
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.ultrasonicRangeRead.rawValue, port.id)
//      usleep(51_000) // firmware has a time of 50ms so wait for more than that
//      _ = try bus1.readByte()
//      bytes = try bus1.readBlock()
//    }
//    return (UInt16(bytes[1]) << 8) | UInt16(bytes[2])
//  }
//
//  fileprivate func directWriteAnalogueValue(_ value: UInt8) throws {
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.analogWrite.rawValue, port.id, value)
//    }
//  }
//
//  fileprivate func directWriteDigitalValue(_ value: DigitalValue) throws {
//    try bus1.criticalSection.locked {
//      try bus1.writeBlock(Command.digitalWrite.rawValue, port.id, value.rawValue)
//    }
//  }
//}
//
//extension GrovePiArduinoBus1 {
//  // MARK: - private GrovePiBus implementation
//
//  fileprivate func openIO() throws {
//    #if os(Linux)
//      fd = open("/dev/i2c-1", O_RDWR) // bus number 1
//      if fd < 0 {
//        throw GrovePiError.OpenError(errno)
//      }
//      if ioctl(fd, UInt(I2C_SLAVE), 0x04/*Arduino*/) != 0 {
//        throw GrovePiError.IOError(errno)
//      }
//    #endif
//  }
//
//  fileprivate func readByte() throws -> UInt8 {
//    #if os(Linux)
//      var result: Int32 = 0;
//      for _ in 0...retryCount {
//        r_buf[0] = 0
//        result = i2c_smbus_read_byte(fd)
//        if result >= 0 {
//          break
//        }
//        usleep(delayBeforeRetryInMicroSeconds)
//      }
//      if result < 0 {
//        throw GrovePiError.IOError(errno)
//      }
//      r_buf[0] = UInt8(result)
//      return UInt8(result)
//    #else
//      return 0
//    #endif
//  }
//
//  fileprivate func readBlock() throws -> [UInt8] {
//    #if os(Linux)
//      var result: Int32 = 0;
//      for _ in 0...retryCount {
//        for i in 1..<r_buf.count { r_buf[i] = 0 }
//        result = i2c_smbus_read_i2c_block_data(fd, 1, UInt8(r_buf.count), &r_buf[0])
//        if result >= 0 {
//          break
//        }
//        usleep(delayBeforeRetryInMicroSeconds)
//      }
//      if result < 0 {
//        throw GrovePiError.IOError(errno)
//      }
//      return r_buf
//    #else
//      return [UInt8](repeating: 0, count: 32)
//    #endif
//  }
//
//  fileprivate func writeBlock(_ cmd: UInt8, _ v1: UInt8, _ v2: UInt8 = 0, _ v3: UInt8 = 0) throws {
//    #if os(Linux)
//      w_buf[0] = cmd; w_buf[1] = v1; w_buf[2] = v2; w_buf[3] = v3
//      var result: Int32 = 0;
//      for _ in 0...retryCount {
//        result = i2c_smbus_write_i2c_block_data(fd, 1, UInt8(w_buf.count), w_buf)
//        if result >= 0 {
//          break
//        }
//        usleep(delayBeforeRetryInMicroSeconds)
//      }
//      if (result < 0) {
//        throw GrovePiError.IOError(errno)
//      }
//    #endif
//  }
//
//}
//
//
//
//
//
//
