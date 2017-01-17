//
//  GrovePiBusScanner.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 17-01-17.
//
//

import Foundation

final class GrovePiBusScanner {
  private var scanItems: [ScanItem]

  init() {
    scanItems = []
  }

  func addScanItem(portLabel: GrovePiPortLabel, sampleTimeInterval: TimeInterval, evaluation: @escaping () throws -> ()) {
    let scanItem = ScanItem(portLabel: portLabel, sampleTimeInterval: sampleTimeInterval, evaluation: evaluation)
    scanItems.append(scanItem)
  }

  func removeScanItem(portLabel: GrovePiPortLabel) {
    let equatablePortLabel = EquatablePortLabel(portLabel)
    if let toBeRemovedIndex = scanItems.index(where: { return $0.equatablePortLabel == equatablePortLabel }) {
      scanItems.remove(at: toBeRemovedIndex)
    }
  }
}

extension GrovePiInputProtocol where InputValue == AnalogueValue10 {
  public func areSignificantDifferent(newValue: AnalogueValue10, previousValue: AnalogueValue10) -> Bool {
    return abs(Int16(newValue) - Int16(previousValue)) >= 2
  }
}

extension GrovePiInputProtocol where InputValue == DigitalValue {
  public func areSignificantDifferent(newValue: DigitalValue, previousValue: DigitalValue) -> Bool {
    return newValue.rawValue != previousValue.rawValue
  }
}

private struct ScanItem {
  let equatablePortLabel: EquatablePortLabel
  let sampleTimeInterval: TimeInterval
  let evaluation: () throws -> ()
  var nextTimeInterval: TimeInterval

  init(portLabel: GrovePiPortLabel, sampleTimeInterval: TimeInterval, evaluation: @escaping () throws -> ()) {
    self.equatablePortLabel = EquatablePortLabel(portLabel)
    self.sampleTimeInterval = sampleTimeInterval
    self.evaluation = evaluation
    nextTimeInterval = ScanItem.alignedInitialTimeInterval(sampleTimeInterval)
  }

  mutating func evaluate() throws {
    try evaluation()
    repeat {
      nextTimeInterval += sampleTimeInterval
    } while nextTimeInterval <= Date.timeIntervalSinceReferenceDate
  }

  private static func alignedInitialTimeInterval(_ sampleTimeInterval: TimeInterval) -> TimeInterval {
    let nowReference = Date.timeIntervalSinceReferenceDate
    return nowReference - nowReference.truncatingRemainder(dividingBy: sampleTimeInterval)
  }
}

