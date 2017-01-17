//
//  GrovePiPortLabel.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public enum PortType: String, CustomStringConvertible {
  case analogue, digital, i2c, uart

  public var description: String { return rawValue }
}

public protocol GrovePiPortLabel: CustomStringConvertible {
  var type: PortType { get }
  var id: UInt8 { get }
}

public enum GrovePiAnaloguePortLabel: String, GrovePiPortLabel {
  case A0, A1, A2

  public var type: PortType { return .analogue }
  public var id: UInt8 {
    switch self {
    case .A0: return 0
    case .A1: return 1
    case .A2: return 2
    }
  }
  public var description: String { return rawValue }
}

public enum GrovePiDigitalPortLabel: String, GrovePiPortLabel {
  case D2, D3, D4, D5, D6, D7, D8

  public var type: PortType { return .digital }
  public var id: UInt8 {
    switch self {
    case .D2: return 2
    case .D3: return 3
    case .D4: return 4
    case .D5: return 5
    case .D6: return 6
    case .D7: return 7
    case .D8: return 8
    }
  }
  public var description: String { return rawValue }
}

public enum GrovePiI2CPortLabel: String, GrovePiPortLabel {
  case I2C_1 = "I2C-1"
  case I2C_2 = "I2C-2"
  case I2C_3 = "I2C-3"

  public var type: PortType { return .i2c }
  public var id: UInt8 {
    switch self {
    case .I2C_1: return 1
    case .I2C_2: return 2
    case .I2C_3: return 3
    }
  }
  public var description: String { return rawValue }
}

public enum GrovePiUARTPortLabel: String, GrovePiPortLabel {
  case rpiSerial = "RPISER"
  case serial = "SERIAL"

  public var type: PortType { return .uart }
  public var id: UInt8 {
    switch self {
    case .rpiSerial: return 1
    case .serial: return 2
    }
  }
  public var description: String { return rawValue }

}

public struct EquatablePortLabel: Equatable, Hashable {
  public let portLabel: GrovePiPortLabel
  public var hashValue: Int { return portLabel.description.hashValue }

  public init(_ portLabel: GrovePiPortLabel) {
    self.portLabel = portLabel
  }

  public static func ==(lhs: EquatablePortLabel, rhs: EquatablePortLabel) -> Bool {
    return lhs.portLabel.type == rhs.portLabel.type && lhs.portLabel.id == rhs.portLabel.id
  }
}

