//
//  TimeInterval+Seconds.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 16-01-17.
//
//

import Foundation

internal extension TimeInterval {
  var microseconds: UInt32 { return UInt32(self * 1_000_000.0) }
  var nanoseconds: UInt64 { return UInt64(self * 1_000_000_000.0) }

  init(microseconds: UInt32) {
    self = TimeInterval(Double(microseconds) / 1_000_000.0)
  }

  init(nanoseconds: UInt64) {
    self = TimeInterval(Double(nanoseconds) / 1_000_000_000.0)
  }
}
