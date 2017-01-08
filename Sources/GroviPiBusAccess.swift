//
//  GroviPiBusScanner.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 07-01-17.
//
//

import Foundation

struct SensorScan<DT> {
  let readInput: () throws -> (DT)
  let ifChanged: (DT, DT) -> Bool
  let reportChange: (DT) -> ()
  private var lastValue: DT? = nil

  init(readInput: @escaping () throws -> (DT), ifChanged: @escaping (DT, DT) -> Bool, reportChange: @escaping (DT) -> ()) {
    self.readInput = readInput
    self.ifChanged = ifChanged
    self.reportChange = reportChange
  }

  mutating func checkIfDifferentNewValue(_ newValue: DT) -> Bool {
    let oldValue = lastValue
    lastValue = newValue
    return oldValue == nil || ifChanged(newValue, oldValue!)
  }
}

enum SensorOutputType: UInt8 {
  case analogueValue = 1
  case digitalValue = 2
  case twoFloatValues = 4
}

final class SensorScanChangeReportID: ChangeReportID {
  private(set) weak var source: GrovePiIO?
  let id: Int

  init(source: GrovePiIO, slot: Int, type: SensorOutputType) {
    self.source = source
    self.id = Int(UInt(slot << 8) | UInt(type.rawValue))
  }

  class func outputType(of reportId: ChangeReportID) -> SensorOutputType? {
    return SensorOutputType(rawValue: UInt8(truncatingBitPattern: reportId.id))
  }

}

final class GrovePiBusAccess {
  private var nextSlot: Int = 0
  private var twoFloatsSensorScansMap: [Int:SensorScan<(Float,Float)>] = [:]
  private var analogueSensorScansMap: [Int:SensorScan<(UInt16)>] = [:]
  private var digitalSensorScansMap: [Int:SensorScan<(DigitalValue)>] = [:]
  private let busAccessOperations: BusAccessOperations
  private let criticalSectionLock: NSRecursiveLock

  init() {
    criticalSectionLock = NSRecursiveLock()
    busAccessOperations = BusAccessOperations()
  }

  deinit {
    busAccessOperations.stopScansTask()
  }

  func addTwoFloatsSensorScan(at port: GrovePiIO, readInput: @escaping () throws -> ((Float,Float)),
                                ifChanged: @escaping ((Float,Float), (Float,Float)) -> Bool,
                                reportChange: @escaping ((Float,Float)) -> ()) -> ChangeReportID {
    criticalSectionLock.lock()
    defer { criticalSectionLock.unlock() }
    checkScansStatusBeforeAdd()
    let reportID = SensorScanChangeReportID(source: port, slot: nextSlot, type: .twoFloatValues)
    nextSlot += 1
    twoFloatsSensorScansMap[reportID.id] = SensorScan(readInput: readInput, ifChanged: ifChanged, reportChange: reportChange)
    return reportID
  }
  
  func addAnalogueSensorScan(at port: GrovePiIO, readInput: @escaping () throws -> (UInt16),
                             ifChanged: @escaping (UInt16, UInt16) -> Bool,
                             reportChange: @escaping (UInt16) -> ()) -> ChangeReportID {
    criticalSectionLock.lock()
    defer { criticalSectionLock.unlock() }
    checkScansStatusBeforeAdd()
    let reportID = SensorScanChangeReportID(source: port, slot: nextSlot, type: .analogueValue)
    nextSlot += 1
    analogueSensorScansMap[reportID.id] = SensorScan(readInput: readInput, ifChanged: ifChanged, reportChange: reportChange)
    return reportID
  }

  func addDigitalSensorScan(at port: GrovePiIO, readInput: @escaping () throws -> (DigitalValue),
                             ifChanged: @escaping (DigitalValue, DigitalValue) -> Bool,
                             reportChange: @escaping (DigitalValue) -> ()) -> ChangeReportID {
    criticalSectionLock.lock()
    defer { criticalSectionLock.unlock() }
    checkScansStatusBeforeAdd()
    let reportID = SensorScanChangeReportID(source: port, slot: nextSlot, type: .digitalValue)
    nextSlot += 1
    digitalSensorScansMap[reportID.id] = SensorScan(readInput: readInput, ifChanged: ifChanged, reportChange: reportChange)
    return reportID
  }

  func countScans() -> Int {
    criticalSectionLock.lock()
    defer { criticalSectionLock.unlock() }
    return twoFloatsSensorScansMap.count + analogueSensorScansMap.count + digitalSensorScansMap.count
  }

  func removeSensorScan(withID changeReportID: ChangeReportID, from port: GrovePiIO) {
    guard let sensorScanPort = changeReportID.source, sensorScanPort == port,
        let outputType = SensorScanChangeReportID.outputType(of: changeReportID) else {
      return
    }
    criticalSectionLock.lock()
    defer { criticalSectionLock.unlock() }
    switch outputType {
    case .twoFloatValues:
      _ = twoFloatsSensorScansMap.removeValue(forKey: changeReportID.id)
      break
    case .analogueValue:
      _ = analogueSensorScansMap.removeValue(forKey: changeReportID.id)
      break
    case .digitalValue:
      _ = digitalSensorScansMap.removeValue(forKey: changeReportID.id)
      break
    }
    checkScansStatusAfterRemove()
  }

  func readTwoFloats(readInput: @escaping () throws -> ((Float,Float))) rethrows -> (Float, Float) {
    print("TODO implement readTwoFloats")
    return try readInput()
  }

  func readAnalogueValue(readInput: @escaping () throws -> (UInt16)) rethrows -> UInt16 {
    print("TODO implement readAnalogueValue")
    return try readInput()
  }

  func readDigitalValue(readInput: @escaping () throws -> (DigitalValue)) rethrows -> DigitalValue {
    print("TODO implement readDigitalValue")
    return try readInput()
  }

  func writeAnalogueValue(_ value: UInt8, writeOutput: (UInt8) throws -> ()) rethrows {
    print("TODO implement writeAnalogueValue")
    try writeOutput(value)
  }

  func writeDigitalValue(_ value: DigitalValue, writeOutput: (DigitalValue) throws -> ()) rethrows {
    print("TODO implement writeDigitalValue")
    try writeOutput(value)
  }

  private func checkScansStatusBeforeAdd() {
    if countScans() == 0 {
      busAccessOperations.start(doScansTask: doScans)
    }
  }

  private func checkScansStatusAfterRemove() {
    if countScans() == 0 {
      busAccessOperations.stopScansTask()
    }
  }

  private func doScans() {
    doTwoFloatsScans()
    doAnalogueScans()
    doDigitalScans()
    checkScansStatusAfterRemove()
  }

  private func doTwoFloatsScans() {
    var twoFloatsCopy: [Int:SensorScan<(Float,Float)>] = [:]
    criticalSectionLock.lock()
    if !twoFloatsSensorScansMap.isEmpty {
      twoFloatsSensorScansMap.forEach { twoFloatsCopy[$0.key] = $0.value }
    }
    criticalSectionLock.unlock()
    guard !twoFloatsCopy.isEmpty else { return }
    var twoFloatsUpdates: [Int:SensorScan<(Float,Float)>] = [:]
    var twoFloatsRemovals: [Int] = []
    twoFloatsCopy.forEach{ key, value in
      do {
        if let newScan = try doScan(value) {
          twoFloatsUpdates[key] = newScan
        }
      } catch {
        twoFloatsRemovals.append(key)
      }
    }
    criticalSectionLock.lock()
    twoFloatsUpdates.forEach { key, value in
      if twoFloatsSensorScansMap[key] != nil {
        twoFloatsSensorScansMap[key] = value
      }
    }
    twoFloatsRemovals.forEach { key in twoFloatsSensorScansMap.removeValue(forKey: key) }
    criticalSectionLock.unlock()
  }

  private func doAnalogueScans() {
    var analogueCopy: [Int:SensorScan<(UInt16)>] = [:]
    criticalSectionLock.lock()
    if !analogueSensorScansMap.isEmpty {
      analogueSensorScansMap.forEach { analogueCopy[$0.key] = $0.value }
    }
    criticalSectionLock.unlock()
    guard !analogueCopy.isEmpty else { return }
    var analogueUpdates: [Int:SensorScan<UInt16>] = [:]
    var analogueRemovals: [Int] = []
    analogueCopy.forEach{ key, value in
      do {
        if let newScan = try doScan(value) {
          analogueUpdates[key] = newScan
        }
      } catch {
        analogueRemovals.append(key)
      }
    }
    criticalSectionLock.lock()
    analogueUpdates.forEach { key, value in
      if analogueSensorScansMap[key] != nil {
        analogueSensorScansMap[key] = value
      }
    }
    analogueRemovals.forEach { key in analogueSensorScansMap.removeValue(forKey: key) }
    criticalSectionLock.unlock()
  }

  private func doDigitalScans() {
    var digitalCopy: [Int:SensorScan<(DigitalValue)>] = [:]
    criticalSectionLock.lock()
    if !digitalSensorScansMap.isEmpty {
      digitalSensorScansMap.forEach { digitalCopy[$0.key] = $0.value }
    }
    criticalSectionLock.unlock()
    guard !digitalCopy.isEmpty else { return }
    var digitalUpdates: [Int:SensorScan<DigitalValue>] = [:]
    var digitalRemovals: [Int] = []
    digitalCopy.forEach{ key, value in
      do {
        if let newScan = try doScan(value) {
          digitalUpdates[key] = newScan
        }
      } catch {
        digitalRemovals.append(key)
      }
    }
    criticalSectionLock.lock()
    digitalUpdates.forEach { key, value in
      if digitalSensorScansMap[key] != nil {
        digitalSensorScansMap[key] = value
      }
    }
    digitalRemovals.forEach { key in digitalSensorScansMap.removeValue(forKey: key) }
    criticalSectionLock.unlock()
  }

  private func doScan<DT>(_ sensorScan: SensorScan<DT>) throws -> SensorScan<DT>? {
    let newValue: DT = try sensorScan.readInput()
    var newSensorScan = sensorScan
    if newSensorScan.checkIfDifferentNewValue(newValue) {
      busAccessOperations.addOtherOperation {
        newSensorScan.reportChange(newValue)
      }
      return newSensorScan
    }
    return nil
  }

}

enum ReadyState: Int {
  case waiting = 0
  case busy = 1
}

fileprivate final class BusAccessOperations {
  private let serialQueue: OperationQueue
  private let otherOperationQueue: OperationQueue
  private let readyLock: NSConditionLock
  private var scanSchedulerOperation: ScanSchedulerOperation?

  init() {
    serialQueue = OperationQueue()
    serialQueue.qualityOfService = .utility
    serialQueue.maxConcurrentOperationCount = 1
    otherOperationQueue = OperationQueue()
    otherOperationQueue.qualityOfService = .default
    readyLock = NSConditionLock(condition: .waiting)
  }

  func start(doScansTask: @escaping () -> ()) {
    scanSchedulerOperation = ScanSchedulerOperation(readyLock: readyLock, serialQueue: serialQueue, doScansTask: doScansTask)
    otherOperationQueue.addOperation(scanSchedulerOperation!)
  }

  func addOtherOperation(_ block: @escaping () -> ()) {
    otherOperationQueue.addOperation(block)
  }

  func stopScansTask() {
    if let op = scanSchedulerOperation {
      scanSchedulerOperation = nil
      op.cancel()
    }
  }

}

fileprivate final class ScanSchedulerOperation: Operation {
  let pollTimeoutInMicroSeconds: useconds_t = 50_000
  private unowned var readyLock: NSConditionLock
  private unowned var serialQueue: OperationQueue
  private let doScansTask: () -> ()

  init(readyLock: NSConditionLock, serialQueue: OperationQueue, doScansTask: @escaping () -> ()) {
    self.readyLock = readyLock
    self.serialQueue = serialQueue
    self.doScansTask = doScansTask
  }

  override func main() {
    while !isCancelled {
      readyLock.lock(whenCondition: .waiting)
      usleep(pollTimeoutInMicroSeconds)
      serialQueue.addOperation {
        self.readyLock.lock(whenCondition: .busy)
        self.doScansTask()
        self.readyLock.unlock(withCondition: .waiting)
      }
      readyLock.unlock(withCondition: .busy)
    }
  }
}

fileprivate extension NSConditionLock {
  convenience init(condition readyState: ReadyState) {
    self.init(condition: readyState.rawValue)
  }
  func lock(whenCondition readyState: ReadyState) {
    lock(whenCondition: readyState.rawValue)
  }
  func unlock(withCondition readyState: ReadyState) {
    unlock(withCondition: readyState.rawValue)
  }
}

func ==(lhs: GrovePiIO, rhs: GrovePiIO) -> Bool {
  return lhs.port.id == rhs.port.id && lhs.port.type == rhs.port.type
}
