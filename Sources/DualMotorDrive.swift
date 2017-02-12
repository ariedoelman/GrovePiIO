//
//  MotorDrive.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 05-02-17.
//
//

import Foundation

public enum MotorDirection: String {
  case forward, backward, none
}

public struct MotorGearAndDirection {
  public var gear: Range256?
  public var direction: MotorDirection?

  private init(gear: Range256?, direction: MotorDirection?) {
    self.gear = gear
    self.direction = direction
  }

  public init(gear: Range256, direction: MotorDirection) {
    self.gear = gear
    self.direction = direction
  }

  public init(direction: MotorDirection) {
    self.init(gear: nil, direction: direction)
  }

  public init(gear: Range256) {
    self.init(gear: gear, direction: nil)
  }
}

public struct DualMotorGearAndDirection: GrovePiOutputValueType {
  public var motorA: MotorGearAndDirection
  public var motorB: MotorGearAndDirection

  public init(motorA: MotorGearAndDirection, motorB: MotorGearAndDirection) {
    self.motorA = motorA
    self.motorB = motorB
  }

  public init(motorAB: MotorGearAndDirection) {
    self.init(motorA: motorAB, motorB: motorAB)
  }

  public init(gearA: Range256, gearB: Range256) {
    self.init(motorA: MotorGearAndDirection(gear: gearA), motorB: MotorGearAndDirection(gear: gearB))
  }

  public init(gearAB: Range256) {
    self.init(motorAB: MotorGearAndDirection(gear: gearAB))
  }

  public init(directionAB: MotorDirection) {
    self.init(motorAB: MotorGearAndDirection(direction: directionAB))
  }

  public init(directionA: MotorDirection, directionB: MotorDirection) {
    self.init(motorA: MotorGearAndDirection(direction: directionA), motorB: MotorGearAndDirection(direction: directionB))
  }
}

public struct DualMotorDriveUnit: GrovePiOutputUnit {
  public let name = "I2C Motor Drive"
  public let supportedPortTypes = [PortType.i2c]

  public var description: String {
    return "\(name): supported port type(s): \(supportedPortTypes)"
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectDualMotorDrive(portLabel: GrovePiI2CPortLabel) throws -> MotorDriveDestination {
      let actuatorUnit = DualMotorDriveUnit()
      let outputProtocol = MotorDriveProtocol()
      return MotorDriveDestination(try busDelegate.connect(portLabel: portLabel, to: actuatorUnit, using: outputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiOutputDestination

public final class MotorDriveDestination: GrovePiOutputDestination {
  private var delegate: AnyGrovePiOutputDestination<GrovePiI2CPortLabel, DualMotorDriveUnit, DualMotorGearAndDirection>
  public var portLabel: GrovePiI2CPortLabel { return delegate.portLabel }
  public var outputUnit: DualMotorDriveUnit { return delegate.outputUnit }

  public init(_ delegate: AnyGrovePiOutputDestination<GrovePiI2CPortLabel, DualMotorDriveUnit, DualMotorGearAndDirection>) {
    self.delegate = delegate
  }

  public func writeValue(_ value: DualMotorGearAndDirection) throws {
    try delegate.writeValue(value)
  }

  public func connect() throws {
    try delegate.connect()
  }

  public func disconnect() throws {
    try delegate.disconnect()
  }

}

// MARK: - private implementations & extensions

private struct MotorDriveProtocol: GrovePiOutputProtocol {
  var writeCommand: WriteCommandType { return .other }

  func otherWriteCommandImplementation<PL: GrovePiPortLabel>(for outputValue: DualMotorGearAndDirection, to arduinoBus: GrovePiArduinoBus, at _: PL) throws {
    if let gearA = outputValue.motorA.gear, let gearB = outputValue.motorB.gear {
      try arduinoBus.write(motorGearA: gearA, motorGearB: gearB)
    }
    if let directionA = outputValue.motorA.direction, let directionB = outputValue.motorB.direction {
      try arduinoBus.write(motorDirectionA: directionA, motorDirectionB: directionB)
    }
  }

  func convert(outputValue: DualMotorGearAndDirection) -> [UInt8] {
    fatalError()
  }
}

private extension GrovePiArduinoBus {
  var dualMotorDriveAddress: UInt8 { return 0x0F }
  var motorGearCommand: UInt8 { return 0x82 }
  var motorDirectionCommand: UInt8 { return 0xAA }

  func write(motorGearA: UInt8, motorGearB: UInt8) throws {
    if GrovePiBus.printCommands { print("\(Date.hhmmssSSS) Address=\(dualMotorDriveAddress) Write other command=\(motorDirectionCommand)",
      "val1=\(motorGearA)", "val2=\(motorGearB)", separator: ", ") }
    try setAddress(dualMotorDriveAddress)
    try writeBlock(motorGearCommand, motorGearA, motorGearB)
    usleep(20_000)
  }

  func write(motorDirectionA: MotorDirection, motorDirectionB: MotorDirection) throws {
    let mdBits = (motorDirectionToBits(motorDirectionA) << 2) | motorDirectionToBits(motorDirectionB)
    if GrovePiBus.printCommands { print("\(Date.hhmmssSSS) Address=\(dualMotorDriveAddress) Write other command=\(motorDirectionCommand)",
      "val1=\(mdBits)", separator: ", ") }
    try setAddress(dualMotorDriveAddress)
    try writeBlock(motorDirectionCommand, mdBits)
    usleep(20_000)
  }

  private func motorDirectionToBits(_ direction: MotorDirection) -> UInt8 {
    switch direction {
    case .forward: return 0x02
    case .backward: return 0x01
    case .none: return 0x00
    }
  }
}


