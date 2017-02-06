//
//  Buzzer.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 06-02-17.
//
//

import Foundation

public struct BuzzerUnit: GrovePiOutputUnit {
  public let name: String = "Buzzer"
  public let supportedPortTypes = [PortType.digital]

  public var description: String {
    return "\(name): supported port type(s): \(supportedPortTypes)"
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectBuzzer(portLabel: GrovePiDigitalPortLabel) throws -> BuzzerDestination {
      let actuatorUnit = BuzzerUnit()
      let outputProtocol = BuzzerProtocol()
      return BuzzerDestination(try busDelegate.connect(portLabel: portLabel, to: actuatorUnit, using: outputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiOutputDestination

public final class BuzzerDestination: GrovePiOutputDestination {
  private var delegate: AnyGrovePiOutputDestination<GrovePiDigitalPortLabel, BuzzerUnit, DigitalValue>
  public var portLabel: GrovePiDigitalPortLabel { return delegate.portLabel }
  public var outputUnit: BuzzerUnit { return delegate.outputUnit }

  public init(_ delegate: AnyGrovePiOutputDestination<GrovePiDigitalPortLabel, BuzzerUnit, DigitalValue>) {
    self.delegate = delegate
  }

  public func writeValue(_ value: DigitalValue) throws {
    try delegate.writeValue(value)
  }

  public func connect() throws {
    try delegate.connect()
  }

  public func disconnect() throws {
    try delegate.disconnect()
  }
}

// MARK: - private implementations

private struct BuzzerProtocol: GrovePiOutputProtocol {
  public typealias OutputValue = DigitalValue
  // like any other analogue/digital write protocol
}
