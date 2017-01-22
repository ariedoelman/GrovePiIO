//
//  GrovePiOutputSource.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

public protocol GrovePiOutputDestination: class, GrovePiPortConnection {
  associatedtype OutputUnit: GrovePiOutputUnit
  associatedtype OutputValue: GrovePiOutputValueType
  var outputUnit: OutputUnit { get }

  func writeValue(_ value: OutputValue) throws
}

public func ==<OD: GrovePiOutputDestination>(lhs: OD, rhs: OD) -> Bool {
  return lhs.portLabel == rhs.portLabel && lhs.outputUnit == rhs.outputUnit
}

