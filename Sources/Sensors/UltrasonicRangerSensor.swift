//
//  UltrasonicDistanceSensor.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public struct UltrasonicRangerSensor: GrovePiInputUnit {
  public let supportedPortTypes: [PortType]
  public let sampleTimeInterval: TimeInterval
  public let delayReadAfterCommandTimeInterval: TimeInterval

  public init(sampleTimeInterval: TimeInterval = 1.0) {
    self.sampleTimeInterval = sampleTimeInterval
    supportedPortTypes = [.digital]
    delayReadAfterCommandTimeInterval = 0.0505 // firmware has a time of 50ms so wait for more than that
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectUltrasonicRangerSensor(to portLabel: GrovePiDigitalPortLabel, sampleTimeInterval: TimeInterval = 1.0)
    throws -> AnyGrovePiInputSource<AnalogueValue10> {
      let sensor = UltrasonicRangerSensor(sampleTimeInterval: sampleTimeInterval)
      let `protocol` = UltrasonicRangerProtocol()
      return try connect(inputUnit: sensor, to: portLabel, using: `protocol`)
  }
}

public extension UltrasonicRangerSensor {
  public var description: String { return "UltrasonicRangerSensor: port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }
  
}

// MARK: - private implementations

private struct UltrasonicRangerProtocol: GrovePiInputProtocol {
  public typealias InputValue = AnalogueValue10

  public let readCommand: UInt8 = 40
  public let readCommandAdditionalParameters: [UInt8]
  public let responseValueLength: UInt8 = 2

  public init() {
    readCommandAdditionalParameters = []
  }

  public func convert(valueBytes: [UInt8]) -> InputValue {
    return AnalogueValue10(bigEndianBytes: valueBytes)
  }
}

