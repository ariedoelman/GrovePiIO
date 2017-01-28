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
  public var description: String { return rawValue }
}

public struct TemperatureAndHumidity: GrovePiInputValueType {
  public var temperature: Float
  public var humidity: Float
}

public struct TemperatureAndHumiditySensorUnit: GrovePiInputUnit {
  public let name = "Temperature and humidity sensor"
  public let moduleType: DHTModuleType
  public let supportedPortTypes: [PortType]
  public var sampleTimeInterval: TimeInterval

  public var description: String { return "TemperatureAndHumiditySensor: \(moduleType.description), port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }

  fileprivate init(moduleType: DHTModuleType, sampleTimeInterval: TimeInterval) {
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

public extension GrovePiBus {
  func connectTemperatureAndHumiditySensor(to portLabel: GrovePiDigitalPortLabel, moduleType: DHTModuleType = .blue, sampleTimeInterval: TimeInterval = 1.0)
  throws -> TemperatureAndHumiditySensorSource {
    let sensorUnit = TemperatureAndHumiditySensorUnit(moduleType: moduleType, sampleTimeInterval: sampleTimeInterval)
    let inputProtocol = TemperatureAndHumidityProtocol(moduleType: moduleType)
    return TemperatureAndHumiditySensorSource(try busDelegate.connect(portLabel: portLabel, to: sensorUnit, using: inputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiInputSource

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

private struct TemperatureAndHumidityProtocol: GrovePiInputProtocol {
  public typealias InputValue = TemperatureAndHumidity

  public let readCommand: UInt8 = 40
  public let readCommandAdditionalParameters: [UInt8]
  public let responseValueLength: UInt8 = 8
  public let delayReadAfterCommandTimeInterval: TimeInterval = 0.01 // 10 ms

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
    return TemperatureAndHumidity(temperature: temperature, humidity: humidity)
  }

  public func isDifferenceSignificant(newValue: TemperatureAndHumidity, previousValue: TemperatureAndHumidity) -> Bool {
    guard !newValue.temperature.isNaN && !newValue.humidity.isNaN else {
      // if either or both are nan, it is no use to report this, so return no change
      return false
    }
    // this sensor isn't more accurate than 1.0 for both temperature and humidity
    if previousValue.temperature.isNaN || abs(newValue.temperature - previousValue.temperature) >= 1.0 {
      return true
    }
    if previousValue.humidity.isNaN || abs(newValue.humidity - previousValue.humidity) >= 1.0 {
      return true
    }
    return false
  }
}





