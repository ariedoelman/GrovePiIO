//
//  MomentaryOnOffButton.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

public struct MomentaryOnOffButtonUnit: GrovePiInputUnit {
  public let name = "Momentary on/off button"
  public let supportedPortTypes = [PortType.digital]
  public let sampleTimeInterval: TimeInterval

  public var description: String { return "\(name): supported port type(s): \(supportedPortTypes), sample time interval: \(sampleTimeInterval) sec" }

  public init(sampleTimeInterval: TimeInterval = 0.2) {
    self.sampleTimeInterval = sampleTimeInterval
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectMomentaryOnOffButton(portLabel: GrovePiDigitalPortLabel, sampleTimeInterval: TimeInterval = 1.0)
    throws -> MomentaryOnOffButtonSource {
      let sensorUnit = MomentaryOnOffButtonUnit(sampleTimeInterval: sampleTimeInterval)
      let inputProtocol = MomentaryOnOffButtonProtocol()
      return MomentaryOnOffButtonSource(try busDelegate.connect(portLabel: portLabel, to: sensorUnit, using: inputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiInputSource

public final class MomentaryOnOffButtonSource: GrovePiInputSource {
  private var delegate: AnyGrovePiInputSource<GrovePiDigitalPortLabel, MomentaryOnOffButtonUnit, DigitalValue>
  public var portLabel: GrovePiDigitalPortLabel { return delegate.portLabel }
  public var inputUnit: MomentaryOnOffButtonUnit { return delegate.inputUnit }
  public var delegatesCount: Int { return delegate.delegatesCount }

  public init(_ delegate: AnyGrovePiInputSource<GrovePiDigitalPortLabel, MomentaryOnOffButtonUnit, DigitalValue>) {
    self.delegate = delegate
  }

  public func readValue() throws -> DigitalValue {
    return try delegate.readValue()
  }

  public func addValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == DigitalValue*/ {
    return try delegate.addValueChangedDelegate(valueChangedDelegate)
  }

  public func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ valueChangedDelegate: D) throws /*where D.InputValue == DigitalValue*/ {
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

private struct MomentaryOnOffButtonProtocol: GrovePiInputProtocol {
  public typealias InputValue = DigitalValue
  // like any other analogue read protocol
}
