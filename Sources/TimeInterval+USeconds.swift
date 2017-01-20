//
//  TimeInterval+USeconds.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 16-01-17.
//
//

import Foundation

internal extension TimeInterval {
  var uSeconds: UInt32 { return UInt32(self * 1_000_000.0) }

  init(uSeconds: UInt32) {
    self = TimeInterval(uSeconds) / 1_000_000.0
  }
}
