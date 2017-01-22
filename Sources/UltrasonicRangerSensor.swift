//
//  UltrasonicDistanceSensor.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public struct UltrasonicRangerSensorUnit: GrovePiInputUnit {
  public let supportedPortTypes: [PortType]
  public let sampleTimeInterval: TimeInterval
  public let delayReadAfterCommandTimeInterval: TimeInterval

  public init(sampleTimeInterval: TimeInterval = 1.0) {
    self.sampleTimeInterval = sampleTimeInterval
    supportedPortTypes = [.digital]
    delayReadAfterCommandTimeInterval = 0.06 // firmware has a time of 50ms so wait for more than that
  }
}

public typealias DistanceInCentimeters = AnalogueValue10

public final class UltrasonicRangerSensorSource: GrovePiInputSource {
  private var delegate: AnyGrovePiInputSource<GrovePiDigitalPortLabel, UltrasonicRangerSensorUnit, DistanceInCentimeters>
  public var portLabel: GrovePiDigitalPortLabel { return delegate.portLabel }
  public var inputUnit: UltrasonicRangerSensorUnit { return delegate.inputUnit }
  public var delegatesCount: Int { return delegate.delegatesCount }

  public init(_ delegate: AnyGrovePiInputSource<GrovePiDigitalPortLabel, UltrasonicRangerSensorUnit, DistanceInCentimeters>) {
    self.delegate = delegate
  }

  public func readValue() throws -> DistanceInCentimeters {
    return try delegate.readValue()
  }

  public func addValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == DistanceInCentimeters*/ {
    return try delegate.addValueChangedDelegate(valueChangedDelegate)
  }

  public func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == DistanceInCentimeters*/ {
    return try delegate.removeValueChangedDelegate(valueChangedDelegate)
  }

  public func connect() throws {
    try delegate.connect()
  }

  public func disconnect() throws {
    try delegate.disconnect()
  }

}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectUltrasonicRangerSensor(portLabel: GrovePiDigitalPortLabel, sampleTimeInterval: TimeInterval = 1.0)
    throws -> UltrasonicRangerSensorSource {
      let sensorUnit = UltrasonicRangerSensorUnit(sampleTimeInterval: sampleTimeInterval)
      let inputProtocol = UltrasonicRangerProtocol()
      return UltrasonicRangerSensorSource(try busDelegate.connect(portLabel: portLabel, to: sensorUnit, using: inputProtocol))
  }
}

public extension UltrasonicRangerSensorUnit {
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

