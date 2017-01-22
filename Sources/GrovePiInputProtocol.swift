//
//  GrovePiInputProtocol.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

internal protocol GrovePiInputProtocol {
  associatedtype InputValue: GrovePiInputValueType

  var readCommand: UInt8 { get }
  var readCommandAdditionalParameters: [UInt8] { get }
  var delayReadAfterCommandTimeInterval: TimeInterval { get }
  var responseValueLength: UInt8 { get }

  func convert(valueBytes: [UInt8]) -> InputValue
  func isDifferenceSignificant(newValue: InputValue, previousValue: InputValue) -> Bool
}

internal extension GrovePiInputProtocol {
  var delayReadAfterCommandTimeInterval: TimeInterval { return 0.0 } // default delay of 0 s
}

internal extension GrovePiInputProtocol where InputValue == Range1024 {
  var readCommand: UInt8 { return 3 } // default analog read command
  var readCommandAdditionalParameters: [UInt8] { return [] }
  var responseValueLength: UInt8 { return 2 }

  func convert(valueBytes: [UInt8]) -> InputValue {
    return Range1024(bigEndianBytes: valueBytes)
  }

}

internal extension GrovePiInputProtocol where InputValue == DigitalValue {
  var readCommand: UInt8 { return 1 } // default digital read command
  var readCommandAdditionalParameters: [UInt8] { return [] }
  var responseValueLength: UInt8 { return 1 }

  func convert(valueBytes: [UInt8]) -> InputValue {
    return valueBytes[0] == 0 ? .low : .high
  }

}

