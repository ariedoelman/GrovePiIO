//
//  GrovePiBusScanner.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 17-01-17.
//
//

import Foundation
import Dispatch

internal final class GrovePiBusScanner {
  let minimumSampleTimeInterval: TimeInterval = 0.001
  private var scanItems: [ScanItem]
  private var scheduler: Scheduler?
  private let evaluationsQueue: DispatchQueue
  private let criticalSection: Lock

  init() {
    scanItems = []
    evaluationsQueue = DispatchQueue(label: "GrovePi Evaluations", qos: .default, attributes: .concurrent)
    criticalSection = Lock()
  }

  func addScanItem<PL: GrovePiPortLabel>(portLabel: PL, sampleTimeInterval: TimeInterval, evaluation: @escaping (TimeInterval) throws -> ()) {
    let scanItem = ScanItem(portLabel: portLabel,
                            sampleTimeInterval: max(sampleTimeInterval, minimumSampleTimeInterval),
                            evaluation: evaluation)
    criticalSection.lock()
    scanItems.append(scanItem)
    setupAdaptOrRemoveScheduler()
    criticalSection.unlock()
  }

  func removeScanItem<PL: GrovePiPortLabel>(portLabel: PL) {
    let wrappedPortLabel = AnyGrovePiPortLabel(portLabel)
    criticalSection.lock()
    if let toBeRemovedIndex = scanItems.index(where: { return $0.wrappedPortLabel == wrappedPortLabel }) {
      scanItems.remove(at: toBeRemovedIndex)
      setupAdaptOrRemoveScheduler()
    }
    criticalSection.unlock()
  }

  private func setupAdaptOrRemoveScheduler() {
    if scheduler == nil {
      scheduler = Scheduler(initialPollTimeInterval: scanItems.first!.sampleTimeInterval, repeatingJob: { t in
        let snapshotScanItems = self.scanItems.sorted(by: { s1, s2 in s1.sampleTimeInterval < s2.sampleTimeInterval })
        snapshotScanItems.forEach({ scanItem in
          if scanItem.nextTimeInterval <= t {
            self.evaluationsQueue.async {
              do {
                try scanItem.evaluate(timeIntervalSinceReferenceDate: t)
              } catch { // ignore error (report where?)
                // remove it from the list since it caused trouble
                self.removeScanItem(portLabel: scanItem.wrappedPortLabel)
              }
            }
          }
        })
      })
    } else if !scanItems.isEmpty {
      let minimumInterval = scanItems.reduce(1_000_000, { min($0, $1.sampleTimeInterval) })
      if scheduler!.pollTimeInterval != minimumInterval {
        scheduler!.pollTimeInterval = minimumInterval
      }
    } else {
      scheduler!.cancel()
      scheduler = nil
    }

  }

}

extension GrovePiInputProtocol where InputValue == Range1024 {
  func isDifferenceSignificant(newValue: Range1024, previousValue: Range1024) -> Bool {
    return abs(Int(newValue) - Int(previousValue)) >= 1
  }
}

extension GrovePiInputProtocol where InputValue == DigitalValue {
  func isDifferenceSignificant(newValue: DigitalValue, previousValue: DigitalValue) -> Bool {
    return newValue.rawValue != previousValue.rawValue
  }
}

private final class ScanItem {
  let wrappedPortLabel: AnyGrovePiPortLabel
  let sampleTimeInterval: TimeInterval
  let evaluation: (TimeInterval) throws -> ()
  var nextTimeInterval: TimeInterval

  init<PL: GrovePiPortLabel>(portLabel: PL, sampleTimeInterval: TimeInterval, evaluation: @escaping (TimeInterval) throws -> ()) {
    self.wrappedPortLabel = AnyGrovePiPortLabel(portLabel)
    self.sampleTimeInterval = sampleTimeInterval
    self.evaluation = evaluation
    nextTimeInterval = Date.timeIntervalSinceReferenceDate
  }

  func evaluate(timeIntervalSinceReferenceDate: TimeInterval) throws {
    try evaluation(timeIntervalSinceReferenceDate)
    repeat {
      nextTimeInterval += sampleTimeInterval
    } while nextTimeInterval <= timeIntervalSinceReferenceDate
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

  init(initialPollTimeInterval: TimeInterval, repeatingJob: @escaping (TimeInterval) -> ()) {
    dispatchQueue = DispatchQueue(label: "GrovePi Scheduler", qos: .default)
    semaphore = DispatchSemaphore(value: 0)
    self.pollTimeInterval = initialPollTimeInterval
    scanSchedulerWorkItem = DispatchWorkItem(qos: .userInitiated, flags: .assignCurrentContext) {
      var firstTime = true
      guard let myWorkItem = self.scanSchedulerWorkItem else { return }
      var nextTimeSlot = DispatchTime.init(secondsFromNow: -0.001)
      while !myWorkItem.isCancelled {
        if firstTime {
          firstTime = false
        } else {
          let now = DispatchTime.now()
          while nextTimeSlot <= now  {
            nextTimeSlot = nextTimeSlot.added(seconds: self.pollTimeInterval)
          }
          _ = self.semaphore.wait(timeout: nextTimeSlot)
          guard !myWorkItem.isCancelled else { break }
          nextTimeSlot = nextTimeSlot.added(seconds: self.pollTimeInterval)
        }
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


