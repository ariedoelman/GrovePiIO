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

public struct TemperatureAndHumiditySensor: GrovePiInputUnit {
  public let moduleType: DHTModuleType
  public let supportedPortTypes: [PortType]
  public var sampleTimeInterval: TimeInterval

  public init(moduleType: DHTModuleType, sampleTimeInterval: TimeInterval = 1.0) {
    self.moduleType = moduleType
    self.sampleTimeInterval = sampleTimeInterval
    supportedPortTypes = [.digital]
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectTemperatureAndHumiditySensor(to portLabel: GrovePiDigitalPortLabel, moduleType: DHTModuleType = .blue, sampleTimeInterval: TimeInterval = 1.0)
  throws -> AnyGrovePiInputSource<TemperatureAndHumidity> {
    let sensor = TemperatureAndHumiditySensor(moduleType: moduleType, sampleTimeInterval: sampleTimeInterval)
    let `protocol` = TemperatureAndHumidityProtocol(sensor: sensor)
    return try connect(inputUnit: sensor, to: portLabel, using: `protocol`)
  }
}

public extension TemperatureAndHumiditySensor {
  public var description: String { return "TemperatureAndHumiditySensor: \(moduleType.description), port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }

}

// MARK: - private implementations

private struct TemperatureAndHumidityProtocol: GrovePiInputProtocol {
  public typealias InputValue = TemperatureAndHumidity

  public let readCommand: UInt8 = 40
  public let readCommandAdditionalParameters: [UInt8]
  public let responseValueLength: UInt8 = 8

  public init(sensor: TemperatureAndHumiditySensor) {
    readCommandAdditionalParameters = [sensor.moduleType.id]
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

  public func areSignificantDifferent(newValue: TemperatureAndHumidity, previousValue: TemperatureAndHumidity) -> Bool {
    if newValue.temperature.isNaN {
      if !previousValue.temperature.isNaN {
        return true
      }
    } else if previousValue.temperature.isNaN || abs(newValue.temperature - previousValue.temperature) >= 1.0 {
      return true
    }
    if newValue.humidity.isNaN {
      if !previousValue.humidity.isNaN {
        return true
      }
    } else if previousValue.humidity.isNaN || abs(newValue.humidity - previousValue.humidity) >= 1.0 {
      return true
    }
    return false
  }
}





