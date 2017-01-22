//
//  LEDLight.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

public enum LEDColor: CustomStringConvertible {
  case red, green, yellow, blue
  case rgb(r: UInt8, g: UInt8, b: UInt8)

  public var description: String {
    switch self {
    case .red: return "Red"
    case .green: return "Green"
    case .yellow: return "Yellow"
    case .blue: return "Blue"
    case .rgb(let r, let g, let b): return "R: \(r) G: \(g) B: \(b)"
    }
  }
}

public struct LEDLightUnit: GrovePiOutputUnit {
  public let name: String
  public let supportedPortTypes = [PortType.digital]
  public let color: LEDColor

  public var description: String {
    return "\(name): supported port type(s): \(supportedPortTypes)"
  }

  public init(color: LEDColor) {
    self.color = color
    self.name = "\(color.description) LED"
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectLEDLight(portLabel: GrovePiDigitalPortLabel, color: LEDColor)
    throws -> LEDLightDestination {
      let actuatorUnit = LEDLightUnit(color: color)
      let outputProtocol = LEDLightProtocol()
      return LEDLightDestination(try busDelegate.connect(portLabel: portLabel, to: actuatorUnit, using: outputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiOutputSource

public final class LEDLightDestination: GrovePiOutputDestination {
  private var delegate: AnyGrovePiOutputDestination<GrovePiDigitalPortLabel, LEDLightUnit, Range256>
  public var portLabel: GrovePiDigitalPortLabel { return delegate.portLabel }
  public var outputUnit: LEDLightUnit { return delegate.outputUnit }

  public init(_ delegate: AnyGrovePiOutputDestination<GrovePiDigitalPortLabel, LEDLightUnit, Range256>) {
    self.delegate = delegate
  }

  public func writeValue(_ value: Range256) throws {
    try delegate.writeValue(value)
  }

  public func writeDigitalValue(_ value: DigitalValue) throws {
    try delegate.writeValue(value == .low ? 0 : 255)
  }

  public func connect() throws {
    try delegate.connect()
  }

  public func disconnect() throws {
    try delegate.disconnect()
  }

}

// MARK: - private implementations

private struct LEDLightProtocol: GrovePiOutputProtocol {
  public typealias OutputValue = Range256
  // like any other analogue/digital write protocol
}
