//
//  GrovePiInputSource.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 21-01-17.
//
//

import Foundation

public protocol GrovePiInputSource: class, GrovePiPortConnection {
  associatedtype InputValue: GrovePiInputValueType
  var delegatesCount: Int { get }

  func readValue() throws -> InputValue
  func addValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws //where D.InputValue == InputValue
  func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws //where D.InputValue == InputValue
}

public func ==<IS: GrovePiInputSource>(lhs: IS, rhs: IS) -> Bool {
  return lhs.portLabel == rhs.portLabel && lhs.inputUnit == rhs.inputUnit
}

