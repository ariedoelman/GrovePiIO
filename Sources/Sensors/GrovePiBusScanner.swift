//
//  GrovePiBusScanner.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 17-01-17.
//
//

import Foundation

internal final class GrovePiBusScanner {
  let minimumSampleTimeInterval: TimeInterval = 0.033
  private var scanItems: [ScanItem]
  private var scheduler: Scheduler?
  private let evaluationsQueue: DispatchQueue
  private let criticalSection: Lock

  init() {
    scanItems = []
    evaluationsQueue = DispatchQueue(label: "GrovePi Evaluations", qos: .default, attributes: .concurrent)
    criticalSection = Lock()
  }

  func addScanItem(portLabel: GrovePiPortLabel, sampleTimeInterval: TimeInterval, evaluation: @escaping (TimeInterval) throws -> ()) {
    let scanItem = ScanItem(portLabel: portLabel,
                            sampleTimeInterval: max(sampleTimeInterval, minimumSampleTimeInterval),
                            evaluation: evaluation)
    criticalSection.lock()
    scanItems.append(scanItem)
    setupAdaptOrRemoveScheduler()
    criticalSection.unlock()
  }

  func removeScanItem(portLabel: GrovePiPortLabel) {
    let equatablePortLabel = EquatablePortLabel(portLabel)
    criticalSection.lock()
    if let toBeRemovedIndex = scanItems.index(where: { return $0.equatablePortLabel == equatablePortLabel }) {
      scanItems.remove(at: toBeRemovedIndex)
      setupAdaptOrRemoveScheduler()
    }
    criticalSection.unlock()
  }

  private func setupAdaptOrRemoveScheduler() {
    if scheduler == nil {
      scheduler = Scheduler(pollTimeInterval: scanItems.first!.sampleTimeInterval, repeatingJob: { t in
        let snapshotScanItems = self.scanItems
        snapshotScanItems.forEach({ scanItem in
          if scanItem.nextTimeInterval <= t {
            self.evaluationsQueue.async {
              do {
                try scanItem.evaluate(timeIntervalSinceReferenceDate: t)
              } catch { // ignore error (report where?)
                // remove it from the list since it caused trouble
                self.removeScanItem(portLabel: scanItem.equatablePortLabel.portLabel)
              }
            }
          }
        })
      })
    } else if !scanItems.isEmpty {
      let minimumInterval = scanItems.reduce(1_000_000, { min($0, $1.sampleTimeInterval) })
      if scheduler!.pollTimeInterval != minimumInterval {
        scheduler?.pollTimeInterval = minimumInterval
      }
    } else {
      scheduler!.cancel()
      scheduler = nil
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

private final class ScanItem {
  let equatablePortLabel: EquatablePortLabel
  let sampleTimeInterval: TimeInterval
  let evaluation: (TimeInterval) throws -> ()
  var nextTimeInterval: TimeInterval

  init(portLabel: GrovePiPortLabel, sampleTimeInterval: TimeInterval, evaluation: @escaping (TimeInterval) throws -> ()) {
    self.equatablePortLabel = EquatablePortLabel(portLabel)
    self.sampleTimeInterval = sampleTimeInterval
    self.evaluation = evaluation
    nextTimeInterval = ScanItem.alignedInitialTimeInterval(sampleTimeInterval)
  }

  func evaluate(timeIntervalSinceReferenceDate: TimeInterval) throws {
    try evaluation(timeIntervalSinceReferenceDate)
    repeat {
      nextTimeInterval += sampleTimeInterval
    } while nextTimeInterval <= timeIntervalSinceReferenceDate
  }

  private static func alignedInitialTimeInterval(_ sampleTimeInterval: TimeInterval) -> TimeInterval {
    let nowReference = Date.timeIntervalSinceReferenceDate
    return nowReference - nowReference.truncatingRemainder(dividingBy: sampleTimeInterval)
  }
}

private final class Scheduler {
  var pollTimeInterval: TimeInterval {
    didSet {
      self.semaphore.signal()
    }
  }
  private let dispatchQueue: DispatchQueue
  private var scanSchedulerWorkItem: DispatchWorkItem?
  private let semaphore: DispatchSemaphore

  init(pollTimeInterval: TimeInterval, repeatingJob: @escaping (TimeInterval) -> ()) {
    dispatchQueue = DispatchQueue(label: "GrovePi Scheduler", qos: .default)
    semaphore = DispatchSemaphore(value: 0)
    self.pollTimeInterval = pollTimeInterval
    scanSchedulerWorkItem = DispatchWorkItem(qos: .userInitiated, flags: .assignCurrentContext) {
      guard let myWorkItem = self.scanSchedulerWorkItem else { return }
      while !myWorkItem.isCancelled {
        _ = self.semaphore.wait(timeout: DispatchTime(secondsFromNow: pollTimeInterval))
        guard !myWorkItem.isCancelled else { break }
        repeatingJob(Date.timeIntervalSinceReferenceDate)
      }
    }
    dispatchQueue.async(execute: scanSchedulerWorkItem!)
  }

  func cancel() {
    if let op = scanSchedulerWorkItem {
      scanSchedulerWorkItem = nil
      op.cancel()
      semaphore.signal()
    }
  }

}


