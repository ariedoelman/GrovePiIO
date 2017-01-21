//
//  MulticastDelegate.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

internal final class MulticastDelegate <D: Equatable, IV> {
  private var delegates = [D]()

  public var count: Int { return delegates.count }

  public func addDelegate(_ delegate: D) {
    delegates.append(delegate)
  }

  public func removeDelegate(_ delegate: D) {
    // Enumerating in reverse order prevents a race condition from happening when removing elements.
    for (index, delegateInArray) in delegates.enumerated().reversed() {
      // If we have a match, remove the delegate from our array
      if delegateInArray == delegate {
        delegates.remove(at: index)
      }
    }
  }

  public func removeAllDelegates() {
    delegates.removeAll(keepingCapacity: false)
  }

  public func invoke(parameter: IV, invocation: (D, IV) -> ()) {
    for delegateInArray in delegates {
      invocation(delegateInArray, parameter)
    }
  }
}
