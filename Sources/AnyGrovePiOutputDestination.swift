//
//  AnyGrovePiOutputDestination.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

public final class AnyGrovePiOutputDestination<PortLabel: GrovePiPortLabel, OutputUnit: GrovePiOutputUnit, OutputValue: GrovePiOutputValueType>: GrovePiOutputDestination {
  private let box: _AnyGrovePiOutputDestinationBoxBase<PortLabel, OutputUnit, OutputValue>
  public var portLabel: PortLabel { return box.portLabel }
  public var outputUnit: OutputUnit { return box.outputUnit }

  public init<IS: GrovePiOutputDestination>(_ base: IS) where IS.PortLabel == PortLabel, IS.OutputUnit == OutputUnit, IS.OutputValue == OutputValue {
    self.box = _AnyGrovePiOutputDestinationBox(base)
  }

  public init(_ any: AnyGrovePiOutputDestination<PortLabel, OutputUnit, OutputValue>) {
    self.box = any.box
  }

  public func writeValue(_ value: OutputValue) throws {
    try box.writeValue(value)
  }

  public func connect() throws {
    try box.connect()
  }
  public func disconnect() throws {
    try box.disconnect()
  }

  public static func ==<PL,IU,IV>(lhs: AnyGrovePiOutputDestination<PL,IU,IV>, rhs: AnyGrovePiOutputDestination<PL,IU,IV>) -> Bool {
    return lhs.box.equals(rhs.box)
  }

}

private final class _AnyGrovePiOutputDestinationBox<IS: GrovePiOutputDestination>: _AnyGrovePiOutputDestinationBoxBase<IS.PortLabel, IS.OutputUnit, IS.OutputValue> {
  let base: IS
  override var portLabel: IS.PortLabel { return base.portLabel }
  override var outputUnit: IS.OutputUnit { return base.outputUnit }

  init(_ base: IS) {
    self.base = base
    super.init()
  }

  override func writeValue(_ value: IS.OutputValue) throws {
    try base.writeValue(value)
  }

  override func connect() throws {
    try base.connect()
  }

  override func disconnect() throws {
    try base.disconnect()
  }

  override func equals(_ rhs: _AnyGrovePiOutputDestinationBoxBase<IS.PortLabel, IS.OutputUnit, IS.OutputValue>) -> Bool {
    guard let rhsBox = rhs as? _AnyGrovePiOutputDestinationBox else {
      return false
    }
    return base == rhsBox.base
  }
}

private class _AnyGrovePiOutputDestinationBoxBase<PortLabel: GrovePiPortLabel, OutputUnit: GrovePiOutputUnit, OutputValue: GrovePiOutputValueType>: GrovePiOutputDestination {
  var portLabel: PortLabel { fatalError() }
  var outputUnit: OutputUnit { fatalError() }
  var delegatesCount: Int { fatalError() }

  func writeValue(_ value: OutputValue) throws { fatalError() }
  func connect() throws { fatalError() }
  func disconnect() throws { fatalError() }

  func equals(_ rhs: _AnyGrovePiOutputDestinationBoxBase) -> Bool { fatalError() }

  static func ==<PL,IU,IV>(lhs: _AnyGrovePiOutputDestinationBoxBase<PL,IU,IV>, rhs: _AnyGrovePiOutputDestinationBoxBase<PL,IU,IV>) -> Bool { fatalError() }
  
}
