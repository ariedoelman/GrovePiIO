//
//  AnyInputValueChangedDelegate.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 21-01-17.
//
//

import Foundation

internal final class AnyInputValueChangedDelegate<InputValue: GrovePiInputValueType>: InputValueChangedDelegate {
  private let box: _AnyInputValueChangedDelegateBoxBase<InputValue>

  public init<IVCD: InputValueChangedDelegate>(_ base: IVCD) /*where IVCD.InputValue == InputValue*/ {
    self.box = autocast(_AnyInputValueChangedDelegateBox(base))
  }

  public init(_ any: AnyInputValueChangedDelegate<InputValue>) {
    self.box = any.box
  }

  public func newInputValue(_ inputData: InputValue, _ timeIntervalSinceReferenceDate: TimeInterval) {
    box.newInputValue(inputData, timeIntervalSinceReferenceDate)
  }

  public static func ==(lhs: AnyInputValueChangedDelegate, rhs: AnyInputValueChangedDelegate) -> Bool {
    return lhs.box.equals(rhs.box)
  }

}

private final class _AnyInputValueChangedDelegateBox<IVCD: InputValueChangedDelegate>: _AnyInputValueChangedDelegateBoxBase<IVCD.InputValue> {
  let base: IVCD

  init(_ base: IVCD) {
    self.base = base
    super.init()
  }

  override func newInputValue(_ inputData: IVCD.InputValue, _ timeIntervalSinceReferenceDate: TimeInterval) {
    base.newInputValue(inputData, timeIntervalSinceReferenceDate)
  }

  override func equals(_ rhs: _AnyInputValueChangedDelegateBoxBase<IVCD.InputValue>) -> Bool {
    guard let rhsBox = rhs as? _AnyInputValueChangedDelegateBox else {
      return false
    }
    return base == rhsBox.base
  }
}

private class _AnyInputValueChangedDelegateBoxBase<InputValue: GrovePiInputValueType>: InputValueChangedDelegate {
  func newInputValue(_ inputData: InputValue, _ timeIntervalSinceReferenceDate: TimeInterval) { fatalError() }

  func equals(_ rhs: _AnyInputValueChangedDelegateBoxBase) -> Bool { fatalError() }

  static func ==(lhs: _AnyInputValueChangedDelegateBoxBase, rhs: _AnyInputValueChangedDelegateBoxBase) -> Bool { fatalError() }

}

func autocast<T>(_ some: Any) -> T {
  return some as! T
}

