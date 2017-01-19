//
//  GrovePiIO.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 29-12-16.
//
//
import Foundation

public enum DigitalValue: UInt8 {
  case high = 1
  case low = 0
}

public typealias AnalogueValue10 = UInt16

public typealias AnalogueValue8 = UInt8

public protocol GrovePiInputValueType { }
public protocol GrovePiOutputValueType { }

extension DigitalValue: GrovePiInputValueType, GrovePiOutputValueType { }
extension AnalogueValue10: GrovePiInputValueType { }
extension AnalogueValue8: GrovePiOutputValueType { }

public enum IOMode: UInt8 {
  case input = 0
  case output = 1
}

public protocol GrovePiIOUnit: CustomStringConvertible {
  var ioMode: IOMode { get }
  var supportedPortTypes: [PortType] { get }
}

public protocol GrovePiInputUnit: GrovePiIOUnit {
  var sampleTimeInterval: TimeInterval { get }
}

public protocol GrovePiInputProtocol {
  associatedtype InputValue: GrovePiInputValueType

  var readCommand: UInt8 { get }
  var readCommandAdditionalParameters: [UInt8] { get }
  var delayReadAfterCommandTimeInterval: TimeInterval { get }
  var responseValueLength: UInt8 { get }

  func convert(valueBytes: [UInt8]) -> InputValue
  func areSignificantDifferent(newValue: InputValue, previousValue: InputValue) -> Bool
}

public protocol GrovePiOutputUnit: GrovePiIOUnit {
  associatedtype OutputValue: GrovePiOutputValueType

}

public protocol InputValueChangedDelegate: class {
  func newInputValue<IDT: GrovePiInputValueType>(_ inputData: IDT, _ timeIntervalSinceReferenceDate: TimeInterval)
}

public protocol GrovePiPortConnection {
  var portLabel: GrovePiPortLabel { get }
  var inputUnit: GrovePiInputUnit { get }

  func disconnect() throws
}

public protocol GrovePiInputSource: class, GrovePiPortConnection {
  associatedtype InputValue: GrovePiInputValueType

  func readValue() throws -> InputValue
  func addValueChangedDelegate(_ delegate: InputValueChangedDelegate)
  func removeValueChangedDelegate(_ delegate: InputValueChangedDelegate)
}

public protocol GrovePiOutputProtocol {
  associatedtype OutputValue: GrovePiOutputValueType

  var writeCommand: UInt8 { get }

  func convert(outputValue: OutputValue) -> [UInt8]
}

public protocol GrovePiOutputDestination {
  associatedtype OutputValue: GrovePiOutputValueType

  func writeValue(_ value: OutputValue) throws
}

// MARK: - default implementations and default values

public extension GrovePiInputUnit {
  public var ioMode: IOMode { return .input }
}

public extension GrovePiOutputUnit {
  public var ioMode: IOMode { return .output }
}



//public enum LEDColor {
//  case green, red, blue
//}

//public protocol GrovePiBus: class {
//  func temperatureAndHumiditySensor(at: GrovePiDigitalPort, moduleType: DHTModuleType) throws -> TemperatureAndHumiditySensor
//  func ultrasonicRangeSensor(at: GrovePiDigitalPort) throws -> UltrasonicRangeSensor
//  func ledLight(at: GrovePiDigitalPort, color: LEDColor) throws -> LEDLight
//  func lightSensor(at: GrovePiAnaloguePort) throws -> LightSensor
//  func momentaryOnOffButton(at: GrovePiDigitalPort) throws -> MomentaryOnOffButton
//  func potentioMeter(at: GrovePiAnaloguePort) throws -> PotentioMeter
//}

//public protocol ChangeReportID: class {
//  weak var source: GrovePiIOUnit? { get }
//  var id: Int { get }
//  func cancel()
//}

//public protocol GrovePiIOUnit {
//  var bus: GrovePiBus { get }
//  var port: GrovePiPortLabel { get }
//  func cancelChangeReport(withID: ChangeReportID)
//  func cancelAllChangeReports()
//}

//
//public protocol LightSensor: GrovePiIOUnit {
//  func readIntensity() throws -> UInt16
//  func onChange(report: @escaping (UInt16) -> ()) -> ChangeReportID
//}
//
//public protocol LEDLight: GrovePiIOUnit {
//  var color: LEDColor{ get }
//  func setValue(_ digitalValue: DigitalValue) throws
//  func setValue(_ value: UInt8) throws
//}
//
//public protocol MomentaryOnOffButton: GrovePiIOUnit {
//  func readState() throws -> DigitalValue
//  func onChange(report: @escaping (DigitalValue) -> ()) -> ChangeReportID
//}
//
//public protocol PotentioMeter: GrovePiIOUnit {
//  func readValue() throws -> UInt16
//  func onChange(report: @escaping (UInt16) -> ()) -> ChangeReportID
//}
//
//public struct GrovePiBusFactory {
//  public static func getBus() throws -> GrovePiBus {
//    return try GrovePiArduinoBus1.getBus()
//  }
//}






