//
//  TemperatureAndHumiditySensor.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public enum DHTModuleType: String, CustomStringConvertible {
  case blue, white

  public var id: UInt8 {
    switch self {
    case .blue: return 0
    case .white: return 1
    }
  }
  public var description: String { return rawValue.capitalized }
}

@available(OSX 10.12, *)
public struct TemperatureAndHumidity: GrovePiInputValueType {
  public var temperature: Measurement<UnitTemperature>
  public var humidity: Measurement<UnitHumidity>
}

public struct TemperatureAndHumiditySensorUnit: GrovePiInputUnit {
  public let name: String
  public let moduleType: DHTModuleType
  public let supportedPortTypes: [PortType]
  public var sampleTimeInterval: TimeInterval

  public var description: String { return "\(name): port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }

  public init(moduleType: DHTModuleType = .blue, sampleTimeInterval: TimeInterval = 10.0) {
    self.name = "Temperature and humidity (\(moduleType.description)) sensor"
    self.moduleType = moduleType
    self.sampleTimeInterval = sampleTimeInterval
    supportedPortTypes = [.digital]
  }

  public static func ==(_ lhs: TemperatureAndHumiditySensorUnit, _ rhs: TemperatureAndHumiditySensorUnit) -> Bool {
    return lhs.ioMode == rhs.ioMode && lhs.sampleTimeInterval == rhs.sampleTimeInterval && lhs.supportedPortTypes == rhs.supportedPortTypes
              && lhs.moduleType == rhs.moduleType
  }
}


// MARK: - Public extensions

@available(OSX 10.12, *)
public extension GrovePiBus {
  func connectTemperatureAndHumiditySensor(to portLabel: GrovePiDigitalPortLabel, moduleType: DHTModuleType = .blue, sampleTimeInterval: TimeInterval = 10.0)
  throws -> TemperatureAndHumiditySensorSource {
    let sensorUnit = TemperatureAndHumiditySensorUnit(moduleType: moduleType, sampleTimeInterval: sampleTimeInterval)
    let inputProtocol = TemperatureAndHumidityProtocol(moduleType: moduleType)
    return TemperatureAndHumiditySensorSource(try busDelegate.connect(portLabel: portLabel, to: sensorUnit, using: inputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiInputSource

@available(OSX 10.12, *)
public final class TemperatureAndHumiditySensorSource: GrovePiInputSource {
  private var delegate: AnyGrovePiInputSource<GrovePiDigitalPortLabel, TemperatureAndHumiditySensorUnit, TemperatureAndHumidity>
  public var portLabel: GrovePiDigitalPortLabel { return delegate.portLabel }
  public var inputUnit: TemperatureAndHumiditySensorUnit { return delegate.inputUnit }
  public var delegatesCount: Int { return delegate.delegatesCount }

  fileprivate init(_ delegate: AnyGrovePiInputSource<GrovePiDigitalPortLabel, TemperatureAndHumiditySensorUnit, TemperatureAndHumidity>) {
    self.delegate = delegate
  }

  public func readValue() throws -> TemperatureAndHumidity {
    return try delegate.readValue()
  }

  public func addValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == TemperatureAndHumidity*/ {
    return try delegate.addValueChangedDelegate(valueChangedDelegate)
  }

  public func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == TemperatureAndHumidity*/ {
    return try delegate.removeValueChangedDelegate(valueChangedDelegate)
  }

  public func connect() throws {
    try delegate.connect()
  }

  public func disconnect() throws {
    try delegate.disconnect()
  }
}

// MARK: - private implementations

@available(OSX 10.12, *)
private struct TemperatureAndHumidityProtocol: GrovePiInputProtocol {
  public typealias InputValue = TemperatureAndHumidity

  public let readCommand: UInt8 = 40
  public let readCommandAdditionalParameters: [UInt8]
  public let responseValueLength: UInt8 = 8
  public var gapBeforeCommandTimeInterval: TimeInterval = 0.0
  public var delayReadAfterCommandTimeInterval: TimeInterval = 0.0
  public var gapAfterReadTimeInterval: TimeInterval = 0.5 // must leave gap of 0.5 s before any other read

  public init(moduleType: DHTModuleType) {
    readCommandAdditionalParameters = [moduleType.id]
  }

  public func convert(valueBytes: [UInt8]) -> InputValue {
    var temperature = Float(ieee754LittleEndianBytes: valueBytes, offset: 0)
    if temperature > -100.0 && temperature < 150.0 {
      temperature = (temperature * 10.0).rounded() / 10.0
    } else {
      temperature = .nan
    }
    var humidity = Float(ieee754LittleEndianBytes: valueBytes, offset: 4)
    if humidity >= 0.0 && humidity <= 100.0 {
      humidity = (humidity * 10.0).rounded() / 10.0
    } else {
      humidity = .nan
    }
    return TemperatureAndHumidity(temperature: Measurement(value: Double(temperature), unit: UnitTemperature.celsius),
                                  humidity: Measurement(value: Double(humidity), unit: UnitHumidity.percentage))
  }

  public func isDifferenceSignificant(newValue: TemperatureAndHumidity, previousValue: TemperatureAndHumidity) -> Bool {
    guard !newValue.temperature.value.isNaN && !newValue.humidity.value.isNaN else {
      // if either or both are nan, it is no use to report this, so return no change
      return false
    }
    // this sensor isn't more accurate than 1.0 for both temperature and humidity
    if previousValue.temperature.value.isNaN || abs(newValue.temperature.value - previousValue.temperature.value) >= 1.0 {
      return true
    }
    if previousValue.humidity.value.isNaN || abs(newValue.humidity.value - previousValue.humidity.value) >= 1.0 {
      return true
    }
    return false
  }
}





