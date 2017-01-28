//
//  SoundSensor.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 24-01-17.
//
//

import Foundation

public struct SoundSensorUnit: GrovePiInputUnit {
  public let name = "Sound sensor"
  public let supportedPortTypes = [PortType.analogue]
  public let sampleTimeInterval: TimeInterval

  public var description: String { return "\(name): supported port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }

  fileprivate init(sampleTimeInterval: TimeInterval) {
    self.sampleTimeInterval = sampleTimeInterval
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectSoundSensor(portLabel: GrovePiAnaloguePortLabel, sampleTimeInterval: TimeInterval = 1.0)
    throws -> SoundSensorSource {
      let sensorUnit = SoundSensorUnit(sampleTimeInterval: sampleTimeInterval)
      let inputProtocol = SoundSensorProtocol()
      return SoundSensorSource(try busDelegate.connect(portLabel: portLabel, to: sensorUnit, using: inputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiInputSource

public final class SoundSensorSource: GrovePiInputSource {
  private var delegate: AnyGrovePiInputSource<GrovePiAnaloguePortLabel, SoundSensorUnit, Range1024>
  public var portLabel: GrovePiAnaloguePortLabel { return delegate.portLabel }
  public var inputUnit: SoundSensorUnit { return delegate.inputUnit }
  public var delegatesCount: Int { return delegate.delegatesCount }

  public init(_ delegate: AnyGrovePiInputSource<GrovePiAnaloguePortLabel, SoundSensorUnit, Range1024>) {
    self.delegate = delegate
  }

  public func readValue() throws -> Range1024 {
    return try delegate.readValue()
  }

  public func addValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == Range1024*/ {
    return try delegate.addValueChangedDelegate(valueChangedDelegate)
  }

  public func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == Range1024*/ {
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

private struct SoundSensorProtocol: GrovePiInputProtocol {
  public typealias InputValue = Range1024
  public let delayReadAfterCommandTimeInterval: TimeInterval = 0.01 // give it some time
  // like any other analogue read protocol
}
