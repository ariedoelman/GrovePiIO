//
//  GrovePiBus.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public final class GrovePiBus {
  private static var bus: GrovePiBus? = nil
  let busDelegate: GrovePiArduinoBus

  public lazy var firmwareVersion: String = {
    return self.busDelegate.firmwareVersion
  }()

  public static func connectBus() throws -> GrovePiBus {
    if bus == nil {
      bus = try GrovePiBus()
    }
    return bus!
  }

  public static func disconnectBus() throws {
    guard let _ = bus else { return }
    bus = nil
    try GrovePiArduinoBus.disconnectBus()
  }

  private init() throws {
    busDelegate = try GrovePiArduinoBus.connectBus()
  }

  deinit {
    try? GrovePiArduinoBus.disconnectBus()
  }

  func disconnect<PL: GrovePiPortLabel>(from portLabel: PL) throws {
    guard GrovePiBus.bus != nil else {
      throw GrovePiError.DisconnectedBus
    }
    try busDelegate.disconnect(from: portLabel)
  }
}



