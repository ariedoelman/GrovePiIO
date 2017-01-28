//
//  UltrasonicDistanceSensor.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public typealias DistanceInCentimeters = UInt16

public struct UltrasonicRangerSensorUnit: GrovePiInputUnit {
  public let name = "Ultrasonic ranger sensor"
  public let supportedPortTypes: [PortType]
  public let sampleTimeInterval: TimeInterval
  public let maximumDistanceInCentimeters: DistanceInCentimeters = 400

  public var description: String { return "\(name): supported port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }

  fileprivate init(sampleTimeInterval: TimeInterval) {
    self.sampleTimeInterval = sampleTimeInterval
    supportedPortTypes = [.digital]
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

// MARK: - Convenience alternative for AnyGrovePiInputSource

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

// MARK: - private implementations

private struct UltrasonicRangerProtocol: GrovePiInputProtocol {
  public typealias InputValue = DistanceInCentimeters

  public let readCommand: UInt8 = 7
  public let delayReadAfterCommandTimeInterval: TimeInterval = 0.06 // firmware has a time of 50ms so wait for more than that
}

