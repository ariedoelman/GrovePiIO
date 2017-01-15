//
//  AnyGrovePiInputSource.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 15-01-17.
//
//

import Foundation

public struct AnyGrovePiInputSource<InputValue: GrovePiInputValueType>: GrovePiInputSource {
  private var box: _AnyGrovePiInputSourceBoxBase<InputValue>

  public var inputChangeDelegates: MulticastDelegate<InputValueChangeDelegate, InputValue> { return box.inputChangeDelegates }

  public init<IS: GrovePiInputSource>(_ base: IS) where IS.InputValue == InputValue {
    self.box = _AnyGrovePiInputSourceBox(base)
  }

  public func readValue() throws -> InputValue {
    return try box.readValue()
  }
}

private final class _AnyGrovePiInputSourceBox<IS: GrovePiInputSource>: _AnyGrovePiInputSourceBoxBase<IS.InputValue> {
  var base: IS
  override var inputChangeDelegates: MulticastDelegate<InputValueChangeDelegate, IS.InputValue> { return base.inputChangeDelegates }

  init(_ base: IS) {
    self.base = base
    super.init()
  }

  override func readValue() throws -> IS.InputValue {
    return try base.readValue()
  }
}

private class _AnyGrovePiInputSourceBoxBase<InputValue: GrovePiInputValueType>: GrovePiInputSource {
  var inputChangeDelegates: MulticastDelegate<InputValueChangeDelegate, InputValue> { fatalError() }

  init() {
  }

  func readValue() throws -> InputValue {
    fatalError()
  }
}
