//
//  GrovePiIO.swift
//  hello-persistence
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

public protocol GrovePiBus {
  func port(_ port: GrovePiPort) -> GrovePiIO
}

public protocol GrovePiIO {
  var bus: GrovePiBus { get }
  var port: GrovePiPort { get }
  func setIOMode(to ioMode: IOMode) throws
  func readAnalogueValue() throws -> UInt16
  func readDigitalValue() throws -> DigitalValue
  func readTemperatureAndHumidity(moduleType: DHTModuleType) throws -> (temperature: Float, humidity: Float)
  func readUltrasonicRange() throws -> UInt16
  func setValue(_ digitalValue: DigitalValue) throws
  func setValue(_ value: UInt8) throws
}

public struct GrovePiBusFactory {
  public static func getBus() throws -> GrovePiBus {
    return try GrovePiArduinoBus1.getBus()
  }
}

public extension GrovePiIO {
  public func readTemperatureAndHumidity() throws -> (temperature: Float, humidity: Float) {
    return try readTemperatureAndHumidity(moduleType: .blue)
  }
}




