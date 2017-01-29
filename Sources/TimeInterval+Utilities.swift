//
//  TimeInterval+Seconds.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 16-01-17.
//
//

import Foundation

internal extension TimeInterval {
  var microseconds: Int32 { return Int32(self * 1_000_000.0) }
  var nanoseconds: Int64 { return Int64(self * 1_000_000_000.0) }

  init(microseconds: Int32) {
    self = TimeInterval(Double(microseconds) / 1_000_000.0)
  }

  init(nanoseconds: Int64) {
    self = TimeInterval(Double(nanoseconds) / 1_000_000_000.0)
  }
}
