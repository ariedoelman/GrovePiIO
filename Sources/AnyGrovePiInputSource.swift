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
}

private final class _AnyGrovePiInputSourceBox<IS: GrovePiInputSource>: _AnyGrovePiInputSourceBoxBase<IS.InputValue> {
  var base: IS

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
}

private class _AnyGrovePiInputSourceBoxBase<InputValue: GrovePiInputValueType>: GrovePiInputSource {
  var inputChangedDelegates: MulticastDelegate<InputValueChangedDelegate, InputValue> { fatalError() }

  func readValue() throws -> InputValue { fatalError() }
  func addValueChangedDelegate(_ delegate: InputValueChangedDelegate) { fatalError() }
  func removeValueChangedDelegate(_ delegate: InputValueChangedDelegate) { fatalError() }

}
