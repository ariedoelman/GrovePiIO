//
//  GrovePiBus.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public protocol GrovePiBus: class {
  func connect<IP: GrovePiInputProtocol>(inputUnit: GrovePiInputUnit,
               to portLabel: GrovePiPortLabel,
               using inputProtocol: IP) throws -> AnyGrovePiInputSource<IP.InputValue>
}



