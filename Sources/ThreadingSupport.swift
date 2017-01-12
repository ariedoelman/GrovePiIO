//
//  ThreadingSupport.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 12-01-17.
//
//

#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif
import Foundation

internal class Lock {

  let mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

  public init() {
    pthread_mutex_init(mutex, nil)
  }

  deinit {
    pthread_mutex_destroy(mutex)
    mutex.deinitialize()
    mutex.deallocate(capacity: 1)
  }

  public func lock() {
    pthread_mutex_lock(mutex)
  }

  public func unlock() {
    pthread_mutex_unlock(mutex)
  }

  public func locked(closure: () throws -> Void) rethrows {
    lock()
    // MUST be deferred to ensure lock releases on throws
    defer { unlock() }

    try closure()
  }
}
