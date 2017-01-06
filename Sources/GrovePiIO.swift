//
//  GrovePiIO.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 29-12-16.
//
//

public enum IOMode: UInt8 {
  case input = 0
  case output = 1
}

public enum GrovePiPort: UInt8 {
  case A0 = 10
  case A1 = 11
  case A2 = 12
  case D2 = 2
  case D3 = 3
  case D4 = 4
  case D5 = 5
  case D6 = 6
  case D7 = 7
  case D8 = 8

  public var id: UInt8 { return rawValue % 10 }
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

public protocol GrovePiBus {
  func temperatureAndHumiditySensor(at: GrovePiPort, moduleType: DHTModuleType) throws -> TemperatureAndHumiditySensor
  func ultrasonicRangeSensor(at: GrovePiPort) throws -> UltrasonicRangeSensor
  func ledLight(at: GrovePiPort, color: LEDColor) throws -> LEDLight
  func lightSensor(at: GrovePiPort) throws -> LightSensor
  func momentaryOnOffButton(at: GrovePiPort) throws -> MomentaryOnOffButton
  func potentioMeter(at: GrovePiPort) throws -> PotentioMeter
}

public protocol GrovePiIO {
  var bus: GrovePiBus { get }
  var port: GrovePiPort { get }
}

public protocol TemperatureAndHumiditySensor: GrovePiIO {
  var moduleType: DHTModuleType { get }
  func readTH() throws -> (temperature: Float, humidity: Float)
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




