//
//  ArduinoPortConnection.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

internal class ArduinoPortConnection<PL: GrovePiPortLabel>: GrovePiPortConnection {
  fileprivate weak var arduinoBus: GrovePiArduinoBus?
  let portLabel: PL
  let ioMode: IOMode
  var isConnected: Bool

  init(arduinoBus: GrovePiArduinoBus, portLabel: PL, ioMode: IOMode) {
    self.arduinoBus = arduinoBus
    self.portLabel = portLabel
    self.ioMode = ioMode
    isConnected = false
  }

  func connect() throws {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard !isConnected else { return } // no problem to connect more than once
    isConnected = true
    try arduinoBus.setIOMode(portID: portLabel.id, ioMode.rawValue)

  }

  func disconnect() throws {
    guard let _ = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard isConnected else { return } // no problem to disconnect more than once
    isConnected = false
  }

  fileprivate func checkConnectionIsOK() throws -> GrovePiArduinoBus {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    guard isConnected else { throw GrovePiError.DisconnectedPort(portDescription: portLabel.description) }
    return arduinoBus
  }

  static func ==(lhs: ArduinoPortConnection, rhs: ArduinoPortConnection) -> Bool {
    return lhs.portLabel == rhs.portLabel
  }
}

internal final class ArduinoInputSource<PL: GrovePiPortLabel, IU: GrovePiInputUnit, IP: GrovePiInputProtocol>: ArduinoPortConnection<PL>, GrovePiInputSource {
  let inputUnit: IU
  let inputProtocol: IP
  let inputChangedDelegates: MulticastDelegate<AnyInputValueChangedDelegate<IP.InputValue>, IP.InputValue>
  let gapBeforeMicroseconds: UInt32
  let delayMicroseconds: UInt32
  let gapAfterMicroseconds: UInt32
  let extraParameters: [UInt8]
  var lastChangedValue: IP.InputValue?
  var delegatesCount: Int { return inputChangedDelegates.count }

  init(arduinoBus: GrovePiArduinoBus, portLabel: PL, inputUnit: IU, inputProtocol: IP) {
    self.inputUnit = inputUnit
    self.inputProtocol = inputProtocol
    inputChangedDelegates = MulticastDelegate()
    gapBeforeMicroseconds = UInt32(inputProtocol.gapBeforeCommandTimeInterval.microseconds)
    delayMicroseconds = UInt32(inputProtocol.delayReadAfterCommandTimeInterval.microseconds)
    gapAfterMicroseconds = UInt32(inputProtocol.gapAfterReadTimeInterval.microseconds)
    let extraBytes = inputProtocol.readCommandAdditionalParameters
    extraParameters = [extraBytes.count > 0 ? extraBytes[0] : 0, extraBytes.count > 1 ? extraBytes[1] : 0]
    super.init(arduinoBus: arduinoBus, portLabel: portLabel, ioMode: inputUnit.ioMode)
  }

  func readValue() throws -> IP.InputValue {
    _ = try checkConnectionIsOK()
    let valueBytes = try readBytes()
    return inputProtocol.convert(valueBytes: valueBytes)
  }

  func addValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == IP.InputValue*/ {
    let arduinoBus = try checkConnectionIsOK()
    inputChangedDelegates.addDelegate(AnyInputValueChangedDelegate(delegate))
    if inputChangedDelegates.count == 1 {
      arduinoBus.scanner.addScanItem(portLabel: portLabel, sampleTimeInterval: inputUnit.sampleTimeInterval, evaluation: valueChangedEvaluation)
    }
  }

  func removeValueChangedDelegate<D: InputValueChangedDelegate>(_ delegate: D) throws /*where D.InputValue == IP.InputValue*/ {
    let arduinoBus = try checkConnectionIsOK()
    inputChangedDelegates.removeDelegate(AnyInputValueChangedDelegate(delegate))
    if inputChangedDelegates.count == 0 {
      arduinoBus.scanner.removeScanItem(portLabel: portLabel)
    }
  }

  override func disconnect() throws {
    try super.disconnect()
    if inputChangedDelegates.count > 0 {
      inputChangedDelegates.removeAllDelegates()
      arduinoBus?.scanner.removeScanItem(portLabel: portLabel)
    }
  }

  static func ==(lhs: ArduinoInputSource, rhs: ArduinoInputSource) -> Bool {
    return lhs.portLabel == rhs.portLabel && lhs.inputUnit == rhs.inputUnit
  }

  private func valueChangedEvaluation(timeIntervalSinceReferenceDate: TimeInterval) throws {
    let newValue = try readValue()
    let previousValue = lastChangedValue
    if previousValue == nil || inputProtocol.isDifferenceSignificant(newValue: newValue, previousValue: previousValue!) {
      inputChangedDelegates.invoke(parameter: newValue, invocation: { $0.newInputValue($1, timeIntervalSinceReferenceDate) })
      lastChangedValue = newValue
    }
  }

  private func readBytes() throws -> [UInt8] {
    guard let arduinoBus = self.arduinoBus else { throw GrovePiError.DisconnectedBus }
    return try arduinoBus.readCommand(command: inputProtocol.readCommand, portID: portLabel.id,
                                      parameter1: extraParameters[0], parameter2: extraParameters[1],
                                      gapBefore: gapBeforeMicroseconds, delay: delayMicroseconds, gapAfter: gapAfterMicroseconds,
                                      returnLength: inputProtocol.responseValueLength)
  }
  
}

internal final class ArduinoOutputDestination<PL: GrovePiPortLabel, OU: GrovePiOutputUnit, OP: GrovePiOutputProtocol>: ArduinoPortConnection<PL>, GrovePiOutputDestination {
  let outputUnit: OU
  let outputProtocol: OP

  init(arduinoBus: GrovePiArduinoBus, portLabel: PL, outputUnit: OU, outputProtocol: OP) {
    self.outputUnit = outputUnit
    self.outputProtocol = outputProtocol
    super.init(arduinoBus: arduinoBus, portLabel: portLabel, ioMode: outputUnit.ioMode)
  }

  func writeValue(_ value: OP.OutputValue) throws {
    let arduinoBus = try checkConnectionIsOK()
    switch outputProtocol.writeCommand {
    case .arduino(let command):
      try arduinoBus.writeCommand(command: command, portID: portLabel.id, valueBytes: outputProtocol.convert(outputValue: value))
    case .other:
      try arduinoBus.otherWriteCommand(value: value) { value in
        try outputProtocol.otherWriteCommandImplementation(for: value, to: arduinoBus, at: portLabel)
      }
      break
    }
  }

  static func ==(lhs: ArduinoOutputDestination, rhs: ArduinoOutputDestination) -> Bool {
    return lhs.portLabel == rhs.portLabel && lhs.outputUnit == rhs.outputUnit
  }
}

