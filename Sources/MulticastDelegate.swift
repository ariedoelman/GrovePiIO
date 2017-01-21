//
//  MulticastDelegate.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

internal final class MulticastDelegate <D: Equatable, IV> {
  private var weakDelegates = [WeakWrapper]()

  public var count: Int { return weakDelegates.count }

  public func addDelegate(_ delegate: D) {
    weakDelegates.append(WeakWrapper(value: delegate as AnyObject))
  }

  public func removeDelegate(_ delegate: D) {
    // Enumerating in reverse order prevents a race condition from happening when removing elements.
    for (index, delegateInArray) in weakDelegates.enumerated().reversed() {
      // If we find a nil delegate reference, remove the entry from our array
      guard let delegateInArrayValue = delegateInArray.value as? D else {
        weakDelegates.remove(at: index)
        continue
      }
      // If we have a match, remove the delegate from our array
      if delegateInArrayValue == delegate {
        weakDelegates.remove(at: index)
      }
    }
  }

  public func removeAllDelegates() {
    weakDelegates.removeAll(keepingCapacity: false)
  }

  public func invoke(parameter: IV, invocation: (D, IV) -> ()) {
    for delegateInArray in weakDelegates {
      // Since these are weak references, "value" may be nil
      // at some point when ARC is 0 for the object.
      guard let delegateInArrayValue = delegateInArray.value as? D else {
        continue
      }
      invocation(delegateInArrayValue, parameter)
    }
  }
}

private class WeakWrapper {
  weak var value: AnyObject?

  init(value: AnyObject) {
    self.value = value
  }
}

