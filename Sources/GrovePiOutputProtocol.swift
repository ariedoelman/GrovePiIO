//
//  GrovePiOutputProtocol.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

internal enum WriteCommandType {
  case arduino(command: UInt8)
  case other
}

internal protocol GrovePiOutputProtocol {
  associatedtype OutputValue: GrovePiOutputValueType

  var writeCommand: WriteCommandType { get }

  func convert(outputValue: OutputValue) -> [UInt8]

  func otherWriteCommandImplementation<PL: GrovePiPortLabel>(for outputValue: OutputValue, to arduinoBus: GrovePiArduinoBus, at portLabel: PL) throws
}

internal extension GrovePiOutputProtocol {
  func otherWriteCommandImplementation<PL: GrovePiPortLabel>(for outputValue: OutputValue, to arduinoBus: GrovePiArduinoBus, at portLabel: PL) throws {
    fatalError("Must be implemented for other WriteCommandType")
  }
}

internal extension GrovePiOutputProtocol where OutputValue == Range256 {
  var writeCommand: WriteCommandType { return .arduino(command: 4) } // default analog write command

  func convert(outputValue: OutputValue) -> [UInt8] {
    return [outputValue]
  }
}

internal extension GrovePiOutputProtocol where OutputValue == DigitalValue {
  var writeCommand: WriteCommandType { return .arduino(command: 2) } // default digital write command

  func convert(outputValue: OutputValue) -> [UInt8] {
    return [outputValue == .low ? 0 : 1]
  }
}
