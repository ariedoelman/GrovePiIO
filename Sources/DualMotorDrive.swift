//
//  MotorDrive.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 05-02-17.
//
//

import Foundation

public enum MotorDirection: String {
  case forward, backward
}

public struct MotorSpeedAndDirection {
  public let speed: UInt8?
  public let direction: MotorDirection?

  private init(speed: UInt8?, direction: MotorDirection?) {
    self.speed = speed
    self.direction = direction
  }

  public init(speed: UInt8, direction: MotorDirection) {
    self.init(speed: speed, direction: direction)
  }

  public init(direction: MotorDirection) {
    self.init(speed: nil, direction: direction)
  }

  public init(speed: UInt8) {
    self.init(speed: speed, direction: nil)
  }
}

public struct DualMotorSpeedAndDirection: GrovePiOutputValueType {
  public let motorA: MotorSpeedAndDirection
  public let motorB: MotorSpeedAndDirection

  public init(motorA: MotorSpeedAndDirection, motorB: MotorSpeedAndDirection) {
    self.motorA = motorA
    self.motorB = motorB
  }

  public init(motorAB: MotorSpeedAndDirection) {
    self.init(motorA: motorAB, motorB: motorAB)
  }

  public init(speedAB: UInt8) {
    self.init(motorAB: MotorSpeedAndDirection(speed: speedAB))
  }

  public init(directionAB: MotorDirection) {
    self.init(motorAB: MotorSpeedAndDirection(direction: directionAB))
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
  private var delegate: AnyGrovePiOutputDestination<GrovePiI2CPortLabel, DualMotorDriveUnit, DualMotorSpeedAndDirection>
  public var portLabel: GrovePiI2CPortLabel { return delegate.portLabel }
  public var outputUnit: DualMotorDriveUnit { return delegate.outputUnit }

  public init(_ delegate: AnyGrovePiOutputDestination<GrovePiI2CPortLabel, DualMotorDriveUnit, DualMotorSpeedAndDirection>) {
    self.delegate = delegate
  }

  public func writeValue(_ value: DualMotorSpeedAndDirection) throws {
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

  func otherWriteCommandImplementation<PL: GrovePiPortLabel>(for outputValue: DualMotorSpeedAndDirection, to arduinoBus: GrovePiArduinoBus, at _: PL) throws {
    if let speedA = outputValue.motorA.speed, let speedB = outputValue.motorB.speed {
      try arduinoBus.write(motorSpeedA: speedA, motorSpeedB: speedB)
    }
    if let directionA = outputValue.motorA.direction, let directionB = outputValue.motorB.direction {
      try arduinoBus.write(motorDirectionA: directionA, motorDirectionB: directionB)
    }
  }

  func convert(outputValue: DualMotorSpeedAndDirection) -> [UInt8] {
    fatalError()
  }
}

private extension GrovePiArduinoBus {
  var DUAL_MOTOR_DRIVER_ADDR: UInt8 { return 0x0F }
  var MOTOR_SPEED_CMD: UInt8 { return 0x82 }
  var MOTOR_DIRECTION_CMD: UInt8 { return 0xAA }

  func write(motorSpeedA: UInt8, motorSpeedB: UInt8) throws {
    try setAddress(DUAL_MOTOR_DRIVER_ADDR)
    try writeBlock(MOTOR_SPEED_CMD, motorSpeedA, motorSpeedB)
    usleep(20_000)
  }

  func write(motorDirectionA: MotorDirection, motorDirectionB: MotorDirection) throws {
    try setAddress(DUAL_MOTOR_DRIVER_ADDR)
    try writeBlock(MOTOR_DIRECTION_CMD, (motorDirectionA == .forward ? 0x08 : 0x04) | (motorDirectionA == .forward ? 0x02 : 0x01))
    usleep(20_000)
  }
}


