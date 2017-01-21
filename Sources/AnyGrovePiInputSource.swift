//
//  AnyGrovePiInputSource.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 15-01-17.
//
//

import Foundation

public final class AnyGrovePiInputSource<PortLabel: GrovePiPortLabel, InputUnit: GrovePiInputUnit, InputValue: GrovePiInputValueType>: GrovePiInputSource {
  private let box: _AnyGrovePiInputSourceBoxBase<PortLabel, InputUnit, InputValue>
  public var portLabel: PortLabel { return box.portLabel }
  public var inputUnit: InputUnit { return box.inputUnit }
  public var delegatesCount: Int { return box.delegatesCount }

  public init<IS: GrovePiInputSource>(_ base: IS) where IS.PortLabel == PortLabel, IS.InputUnit == InputUnit, IS.InputValue == InputValue {
    self.box = _AnyGrovePiInputSourceBox(base)
  }

  public init(_ any: AnyGrovePiInputSource<PortLabel, InputUnit, InputValue>) {
    self.box = any.box
  }

  public func readValue() throws -> InputValue {
    return try box.readValue()
  }

  public func addValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == InputValue*/ {
    return try box.addValueChangedDelegate(delegate)
  }

  public func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == InputValue*/ {
    return try box.removeValueChangedDelegate(delegate)
  }

  public func connect() throws {
    try box.connect()
  }
  public func disconnect() throws {
    try box.disconnect()
  }

  public static func ==<PL,IU,IV>(lhs: AnyGrovePiInputSource<PL,IU,IV>, rhs: AnyGrovePiInputSource<PL,IU,IV>) -> Bool {
    return lhs.box.equals(rhs.box)
  }

}

private final class _AnyGrovePiInputSourceBox<IS: GrovePiInputSource>: _AnyGrovePiInputSourceBoxBase<IS.PortLabel, IS.InputUnit, IS.InputValue> {
  let base: IS
  override var portLabel: IS.PortLabel { return base.portLabel }
  override var inputUnit: IS.InputUnit { return base.inputUnit }
  override var delegatesCount: Int { return base.delegatesCount }

  init(_ base: IS) {
    self.base = base
    super.init()
  }

  override func readValue() throws -> IS.InputValue {
    return try base.readValue()
  }

  override func addValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == IS.InputValue*/ {
    return try base.addValueChangedDelegate(delegate)
  }

  override func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == IS.InputValue*/ {
    return try base.removeValueChangedDelegate(delegate)
  }

  override func connect() throws {
    try base.connect()
  }

  override func disconnect() throws {
    try base.disconnect()
  }

  override func equals(_ rhs: _AnyGrovePiInputSourceBoxBase<IS.PortLabel, IS.InputUnit, IS.InputValue>) -> Bool {
    guard let rhsBox = rhs as? _AnyGrovePiInputSourceBox else {
      return false
    }
    return base == rhsBox.base
  }
}

private class _AnyGrovePiInputSourceBoxBase<PortLabel: GrovePiPortLabel, InputUnit: GrovePiInputUnit, InputValue: GrovePiInputValueType>: GrovePiInputSource {
  var portLabel: PortLabel { fatalError() }
  var inputUnit: InputUnit { fatalError() }
  var delegatesCount: Int { fatalError() }

  func readValue() throws -> InputValue { fatalError() }
  func addValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == InputValue*/ { fatalError() }
  func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == InputValue*/ { fatalError() }
  func connect() throws { fatalError() }
  func disconnect() throws { fatalError() }

  func equals(_ rhs: _AnyGrovePiInputSourceBoxBase) -> Bool { fatalError() }

  static func ==<PL,IU,IV>(lhs: _AnyGrovePiInputSourceBoxBase<PL,IU,IV>, rhs: _AnyGrovePiInputSourceBoxBase<PL,IU,IV>) -> Bool { fatalError() }

}
