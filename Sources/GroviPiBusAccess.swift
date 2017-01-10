//
//  GroviPiBusScanner.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 07-01-17.
//
//

import Foundation

final class SensorScan<DT> {
  private(set) weak var source: GrovePiIO?
  let readInput: () throws -> (DT)
  let ifChanged: (DT, DT) -> Bool
  let reportChange: (DT) -> ()
  private var lastValue: DT? = nil

  init(source: GrovePiIO, readInput: @escaping () throws -> (DT), ifChanged: @escaping (DT, DT) -> Bool, reportChange: @escaping (DT) -> ()) {
    self.source = source
    self.readInput = readInput
    self.ifChanged = ifChanged
    self.reportChange = reportChange
  }

  func checkIfDifferentNewValue(_ newValue: DT) -> Bool {
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

  func cancel() {
    source?.cancelChangeReport(withID: self)
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
    twoFloatsSensorScansMap[reportID.id] = SensorScan(source: port, readInput: readInput, ifChanged: ifChanged, reportChange: reportChange)
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
    analogueSensorScansMap[reportID.id] = SensorScan(source: port, readInput: readInput, ifChanged: ifChanged, reportChange: reportChange)
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
    digitalSensorScansMap[reportID.id] = SensorScan(source: port, readInput: readInput, ifChanged: ifChanged, reportChange: reportChange)
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

  func removeAllSensorScan(from port: GrovePiIO) {
    criticalSectionLock.lock()
    defer { criticalSectionLock.unlock() }
    if !twoFloatsSensorScansMap.isEmpty {
      twoFloatsSensorScansMap
        .filter({ (k, v) in v.source != nil && v.source! == port })
        .forEach({(k, _) in twoFloatsSensorScansMap.removeValue(forKey: k)})
    }
    if !analogueSensorScansMap.isEmpty {
      analogueSensorScansMap
        .filter({ (k, v) in v.source != nil && v.source! == port })
        .forEach({(k, _) in analogueSensorScansMap.removeValue(forKey: k)})
    }
    if !digitalSensorScansMap.isEmpty {
      digitalSensorScansMap
        .filter({ (k, v) in v.source != nil && v.source! == port })
        .forEach({(k, _) in digitalSensorScansMap.removeValue(forKey: k)})
    }
    checkScansStatusAfterRemove()
  }

  func readTwoFloats(readInput: @escaping () throws -> ((Float,Float))) throws -> (Float, Float) {
    return try busAccessOperations.readValue(readInput: readInput)
  }

  func readAnalogueValue(readInput: @escaping () throws -> (UInt16)) throws -> UInt16 {
    return try busAccessOperations.readValue(readInput: readInput)
  }

  func readDigitalValue(readInput: @escaping () throws -> (DigitalValue)) throws -> DigitalValue {
    return try busAccessOperations.readValue(readInput: readInput)
  }

  func writeAnalogueValue(_ value: UInt8, writeOutput: @escaping (UInt8) throws -> ()) throws {
    try busAccessOperations.writeValue(value, writeOutput: writeOutput)
  }

  func writeDigitalValue(_ value: DigitalValue, writeOutput: @escaping (DigitalValue) throws -> ()) throws {
    try busAccessOperations.writeValue(value, writeOutput: writeOutput)
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
    twoFloatsUpdates
      .filter({ k, _ in twoFloatsSensorScansMap[k] != nil })
      .forEach { k, v in twoFloatsSensorScansMap[k] = v }
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
    analogueUpdates
      .filter({ k, _ in analogueSensorScansMap[k] != nil })
      .forEach { k, v in analogueSensorScansMap[k] = v }
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
    digitalUpdates
      .filter({ k, _ in digitalSensorScansMap[k] != nil })
      .forEach { k, v in digitalSensorScansMap[k] = v }
    digitalRemovals.forEach { k in digitalSensorScansMap.removeValue(forKey: k) }
    criticalSectionLock.unlock()
  }

  private func doScan<DT>(_ sensorScan: SensorScan<DT>) throws -> SensorScan<DT>? {
    guard sensorScan.source != nil else { return nil }
    let newValue: DT = try sensorScan.readInput()
    let newSensorScan = sensorScan
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
  private let scheduleLock: NSConditionLock
  private var scanSchedulerOperation: ScanSchedulerOperation?

  init() {
    serialQueue = OperationQueue()
    serialQueue.qualityOfService = .utility
    serialQueue.maxConcurrentOperationCount = 1
    otherOperationQueue = OperationQueue()
    otherOperationQueue.qualityOfService = .default
    scheduleLock = NSConditionLock(condition: .waiting)
  }

  func start(doScansTask: @escaping () -> ()) {
    scanSchedulerOperation = ScanSchedulerOperation(readyLock: scheduleLock, serialQueue: serialQueue, doScansTask: doScansTask)
    otherOperationQueue.addOperation(scanSchedulerOperation!)
  }

  func addOtherOperation(_ block: @escaping () -> ()) {
    otherOperationQueue.addOperation(block)
  }

  func readValue<DT>(readInput: @escaping () throws -> (DT)) throws -> DT {
    var result: DT? = nil
    var errorResult: Error? = nil
    var ioMutex = Mutex(initialAcquires: 1)
    serialQueue.addOperation {
      do {
        result = try readInput()
      } catch {
        errorResult = error
      }
      ioMutex.release()
    }
    ioMutex.acquire()
    if let error = errorResult {
      throw error
    }
    return result!
  }

  func writeValue<DT>(_ value: DT, writeOutput: @escaping (DT) throws -> ()) throws {
    var errorResult: Error? = nil
    var ioMutex = Mutex(initialAcquires: 1)
    serialQueue.addOperation {
      do {
        try writeOutput(value)
      } catch {
        errorResult = error
      }
      ioMutex.release()
    }
    ioMutex.acquire()
    if let error = errorResult {
      throw error
    }
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

struct Mutex {
  private var acquires: Int
  private let criticalSection: NSLock
  private let condition: NSCondition
  init(initialAcquires: Int = 0) {
    acquires = initialAcquires
    criticalSection = NSLock()
    condition = NSCondition()
  }
  mutating func acquire() {
    criticalSection.lock()
    while acquires > 0 {
      condition.wait()
    }
    acquires += 1
    criticalSection.unlock()
  }

  mutating func release() {
    criticalSection.lock()
    acquires -= 1
    condition.signal()
    criticalSection.unlock()
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
