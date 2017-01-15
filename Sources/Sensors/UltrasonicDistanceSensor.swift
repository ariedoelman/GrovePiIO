//
//  UltrasonicDistanceSensor.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public protocol UltrasonicDistanceSensor: GrovePiOutputUnit {
  typealias OutputValue = AnalogueValue10
//  func readDistanceInCentimeters() throws -> UInt16
//  func onChange(report: @escaping (UInt16) -> ()) -> ChangeReportID
}

