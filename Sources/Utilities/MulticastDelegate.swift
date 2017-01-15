//
//  MulticastDelegate.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public final class MulticastDelegate <T, DT> {
  private var weakDelegates = [WeakWrapper]()

  public func addDelegate(_ delegate: T) {
    weakDelegates.append(WeakWrapper(value: delegate as AnyObject))
  }

  public func removeDelegate(_ delegate: T) {
    let classDelegate = delegate as AnyObject
    for (index, delegateInArray) in weakDelegates.enumerated().reversed() {
      // If we find a nil delegate reference, remove the entry from our array
      guard let delegateInArrayValue = delegateInArray.value else {
        weakDelegates.remove(at: index)
        continue
      }
      // If we have a match, remove the delegate from our array
      if delegateInArrayValue === classDelegate {
        weakDelegates.remove(at: index)
      }
    }
  }

  public func invoke(parameter: DT, invocation: (T, DT) -> ()) {
    // Enumerating in reverse order prevents a race condition from happening when removing elements.
    for (index, delegateInArray) in weakDelegates.enumerated().reversed() {
      // Since these are weak references, "value" may be nil
      // at some point when ARC is 0 for the object.
      guard let delegateInArrayValue = delegateInArray.value as? T else {
        weakDelegates.remove(at: index)
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

