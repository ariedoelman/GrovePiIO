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
//////
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
////}
//
