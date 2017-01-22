//
//  GrovePiOutputProtocol.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

internal protocol GrovePiOutputProtocol {
  associatedtype OutputValue: GrovePiOutputValueType

  func writeCommand(for outputValue: OutputValue) -> UInt8

  func convert(outputValue: OutputValue) -> [UInt8]
}

internal extension GrovePiOutputProtocol where OutputValue == Range256 {
  func writeCommand(for outputValue: OutputValue) -> UInt8 {
    return 4 // default analog write command
  }

  func convert(outputValue: OutputValue) -> [UInt8] {
    return [outputValue]
  }
}

internal extension GrovePiOutputProtocol where OutputValue == DigitalValue {
  func writeCommand(for outputValue: OutputValue) -> UInt8 {
    return 2 // default digital write command
  }

  func convert(outputValue: OutputValue) -> [UInt8] {
    return [outputValue == .low ? 0 : 1]
  }
}
