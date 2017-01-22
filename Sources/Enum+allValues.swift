//
//  Enum+allValues.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

public protocol EnumCollection : Hashable { }

public extension EnumCollection {
  public static var allValues: [Self] {
    return Array(self.cases())
  }

  private static func cases() -> AnySequence<Self> {
    typealias S = Self
    return AnySequence { () -> AnyIterator<S> in
      var raw = 0
      return AnyIterator {
        let current : Self = withUnsafePointer(to: &raw) {
          $0.withMemoryRebound(to: S.self, capacity: 1) {
            $0.pointee
          }
        }
        guard current.hashValue == raw else {
          return nil
        }
        raw += 1
        return current
      }
    }
  }
}
