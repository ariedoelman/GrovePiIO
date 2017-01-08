//
//  GrovePiIO.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 29-12-16.
//
//
import Foundation

public enum IOMode: UInt8 {
  case input = 0
  case output = 1
}

public enum PortType {
  case analogue, digital, i2c, uart
}

public protocol GrovePiPort {
  var id: UInt8 { get }
  var type: PortType { get }
}

public enum GrovePiAnaloguePort: UInt8 {
  case A0 = 0
  case A1 = 1
  case A2 = 2
}

public enum GrovePiDigitalPort: UInt8 {
  case D2 = 2
  case D3 = 3
  case D4 = 4
  case D5 = 5
  case D6 = 6
  case D7 = 7
  case D8 = 8
}

public enum GrovePiI2CPort: UInt8 {
  case i2c_1 = 1
  case i2c_2 = 2
  case i2c_3 = 3
}

public enum GrovePiUARTPort: UInt8 {
  case rpiSerial = 1
  case serial = 2
}

public enum DigitalValue: UInt8 {
  case high = 1
  case low = 0
}

public enum GrovePiError: Error {
  case OpenError(Int32)
  case IOError(Int32)
}

public enum DHTModuleType: UInt8 {
  case blue = 0
  case white = 1
}

public enum LEDColor {
  case green, red, blue
}

public protocol GrovePiBus: class {
  func temperatureAndHumiditySensor(at: GrovePiDigitalPort, moduleType: DHTModuleType) throws -> TemperatureAndHumiditySensor
  func ultrasonicRangeSensor(at: GrovePiDigitalPort) throws -> UltrasonicRangeSensor
  func ledLight(at: GrovePiDigitalPort, color: LEDColor) throws -> LEDLight
  func lightSensor(at: GrovePiAnaloguePort) throws -> LightSensor
  func momentaryOnOffButton(at: GrovePiDigitalPort) throws -> MomentaryOnOffButton
  func potentioMeter(at: GrovePiAnaloguePort) throws -> PotentioMeter
}

public protocol ChangeReportID: class {
  weak var source: GrovePiIO? { get }
  var id: Int { get }
}

public protocol GrovePiIO: class {
  var bus: GrovePiBus { get }
  var port: GrovePiPort { get }
  func cancelChangeReport(withID: ChangeReportID)
}

public protocol TemperatureAndHumiditySensor: GrovePiIO {
  var moduleType: DHTModuleType { get }
  func readTemperatureAndHumidity() throws -> (temperature: Float, humidity: Float)
  func onChange(report: @escaping (_ temperature: Float, _ humidity: Float) -> ()) -> ChangeReportID
}

public protocol UltrasonicRangeSensor: GrovePiIO {
  func readCentimeters() throws -> UInt16
}

public protocol LightSensor: GrovePiIO {
  func readIntensity() throws -> UInt16
}

public protocol LEDLight: GrovePiIO {
  var color: LEDColor{ get }
  func setValue(_ digitalValue: DigitalValue) throws
  func setValue(_ value: UInt8) throws
}

public protocol MomentaryOnOffButton: GrovePiIO {
  func readState() throws -> DigitalValue
}

public protocol PotentioMeter: GrovePiIO {
  func readValue() throws -> UInt16
}

public struct GrovePiBusFactory {
  public static func getBus() throws -> GrovePiBus {
    return try GrovePiArduinoBus1.getBus()
  }
}






