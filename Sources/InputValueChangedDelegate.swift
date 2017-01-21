//
//  InputValueChangedDelegate.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 21-01-17.
//
//

import Foundation

public protocol InputValueChangedDelegate: class, Equatable {
  associatedtype InputValue: GrovePiInputValueType
  func newInputValue(_ inputData: InputValue, _ timeIntervalSinceReferenceDate: TimeInterval)
}

public final class InputValueChangedReporter<InputValue: GrovePiInputValueType>: InputValueChangedDelegate {
  private let reportNewInput: (InputValue, TimeInterval) -> ()

  public init(reportNewInput: @escaping (InputValue, TimeInterval) -> ()) {
    self.reportNewInput = reportNewInput
  }
  
  public init(reportNewInput: @escaping (InputValue) -> ()) {
    self.reportNewInput = { value, _ in
      reportNewInput(value)
    }
  }

  public func newInputValue(_ inputData: InputValue, _ timeIntervalSinceReferenceDate: TimeInterval) {
    reportNewInput(inputData, timeIntervalSinceReferenceDate)
  }

  public static func ==(lhs: InputValueChangedReporter, rhs: InputValueChangedReporter) -> Bool {
    return lhs === rhs
  }
}
