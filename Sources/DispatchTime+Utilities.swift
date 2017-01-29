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

extension DispatchTime {
  /**
   Create a dispatch time for a given seconds from now.
   */
  public init(secondsFromNow: TimeInterval) {
    let uptime = DispatchTime.now().uptimeNanoseconds + secondsFromNow.nanoseconds
    self.init(uptimeNanoseconds: uptime)
  }

  /**
   Create a dispatch time for a given nanoseconds from now.
   */
  public init(nanosecondsFromNow: UInt64) {
    let uptime = DispatchTime.now().uptimeNanoseconds + nanosecondsFromNow
    self.init(uptimeNanoseconds: uptime)
  }

  /**
   Create a dispatch time for a given nanoseconds from now.
   */
  public init(microsecondsFromNow: UInt32) {
    let uptime = DispatchTime.now().uptimeNanoseconds + UInt64(microsecondsFromNow) * 1000
    self.init(uptimeNanoseconds: uptime)
  }

  public func nanosecondsFromNow() -> Int64 {
    return Int64(self.rawValue) - Int64(DispatchTime.now().rawValue)
  }

  public func microsecondsFromNow() -> Int64 {
    return nanosecondsFromNow() / 1000
  }

  public func added(seconds: TimeInterval) -> DispatchTime {
    let uptime = self.uptimeNanoseconds + seconds.nanoseconds
    return DispatchTime(uptimeNanoseconds: uptime)
  }
}
