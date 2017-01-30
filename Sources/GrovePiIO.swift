//
//  GrovePiIO.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 29-12-16.
//
//
import Foundation

public enum DigitalValue: UInt8 {
  case high = 1
  case low = 0
}

public typealias Range1024 = UInt16

public typealias Range256 = UInt8

public protocol GrovePiInputValueType { }
public protocol GrovePiOutputValueType { }

extension DigitalValue: GrovePiInputValueType, GrovePiOutputValueType { }
extension Range1024: GrovePiInputValueType { }
extension Range256: GrovePiOutputValueType { }

public extension DigitalValue {
  public var range256: Range256 { return self == .low ? 0 : 255 }
}

public enum IOMode: UInt8 {
  case input = 0
  case output = 1
}

public protocol GrovePiIOUnit: CustomStringConvertible {
  var name: String { get }
  var version: String { get }
  var ioMode: IOMode { get }
  var supportedPortTypes: [PortType] { get }
}

public protocol GrovePiInputUnit: Equatable, GrovePiIOUnit {
  var sampleTimeInterval: TimeInterval { get }
}

public protocol GrovePiOutputUnit: Equatable, GrovePiIOUnit {
//  associatedtype OutputValue: GrovePiOutputValueType

}

public protocol ConnectablePort {
  func connect() throws
  func disconnect() throws
}

public protocol GrovePiPortConnection: class, ConnectablePort, Equatable {
  associatedtype PortLabel: GrovePiPortLabel

  var portLabel: PortLabel { get }
}

// MARK: - default implementations and default values

public extension GrovePiIOUnit {
  public var version: String { return "1.0" }
}

public extension GrovePiInputUnit {
  public var ioMode: IOMode { return .input }
}

public extension GrovePiOutputUnit {
  public var ioMode: IOMode { return .output }
}

public func ==<IU: GrovePiInputUnit>(lhs: IU, rhs: IU) -> Bool {
  return lhs.ioMode == rhs.ioMode && lhs.name == rhs.name
    && lhs.supportedPortTypes == rhs.supportedPortTypes
    && lhs.sampleTimeInterval == rhs.sampleTimeInterval
}

public func ==<IU: GrovePiOutputUnit>(lhs: IU, rhs: IU) -> Bool {
  return lhs.ioMode == rhs.ioMode && lhs.name == rhs.name
    && lhs.supportedPortTypes == rhs.supportedPortTypes
}



