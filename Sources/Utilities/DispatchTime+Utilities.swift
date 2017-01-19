//
//  DispatchTime+Utilities.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 18-01-17.
//
//

#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif
import Foundation
import Dispatch

extension TimeInterval {
  internal var nanoseconds: UInt64 {
    return UInt64(self * Double(1_000_000_000))
  }
}

extension DispatchTime {
  /**
   Create a dispatch time for a given seconds from now.
   */
  public init(secondsFromNow: TimeInterval) {
    let uptime = DispatchTime.now().rawValue + secondsFromNow.nanoseconds
    self.init(uptimeNanoseconds: uptime)
  }
}
