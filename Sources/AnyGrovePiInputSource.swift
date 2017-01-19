//
//  AnyGrovePiInputSource.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 15-01-17.
//
//

import Foundation

public final class AnyGrovePiInputSource<InputValue: GrovePiInputValueType>: GrovePiInputSource {
  private var box: _AnyGrovePiInputSourceBoxBase<InputValue>
  public var inputUnit: GrovePiInputUnit { return box.inputUnit }
  public var portLabel: GrovePiPortLabel { return box.portLabel }

  public init<IS: GrovePiInputSource>(_ base: IS) where IS.InputValue == InputValue {
    self.box = _AnyGrovePiInputSourceBox(base)
  }

  public func readValue() throws -> InputValue {
    return try box.readValue()
  }

  public func addValueChangedDelegate(_ delegate: InputValueChangedDelegate) {
    return box.addValueChangedDelegate(delegate)
  }

  public func removeValueChangedDelegate(_ delegate: InputValueChangedDelegate) {
    return box.removeValueChangedDelegate(delegate)
  }

  public func disconnect() throws {
    try box.disconnect()
  }

}

private final class _AnyGrovePiInputSourceBox<IS: GrovePiInputSource>: _AnyGrovePiInputSourceBoxBase<IS.InputValue> {
  var base: IS
  override var inputUnit: GrovePiInputUnit { return base.inputUnit }
  override var portLabel: GrovePiPortLabel { return base.portLabel }

  init(_ base: IS) {
    self.base = base
    super.init()
  }

  override func readValue() throws -> IS.InputValue {
    return try base.readValue()
  }

  override func addValueChangedDelegate(_ delegate: InputValueChangedDelegate) {
    return base.addValueChangedDelegate(delegate)
  }

  override func removeValueChangedDelegate(_ delegate: InputValueChangedDelegate) {
    return base.removeValueChangedDelegate(delegate)
  }

  override func disconnect() throws {
    try base.disconnect()
  }
}

private class _AnyGrovePiInputSourceBoxBase<InputValue: GrovePiInputValueType>: GrovePiInputSource {
  var portLabel: GrovePiPortLabel { fatalError() }
  var inputUnit: GrovePiInputUnit { fatalError() }

  func readValue() throws -> InputValue { fatalError() }
  func addValueChangedDelegate(_ delegate: InputValueChangedDelegate) { fatalError() }
  func removeValueChangedDelegate(_ delegate: InputValueChangedDelegate) { fatalError() }
  func disconnect() throws { fatalError() }
}
