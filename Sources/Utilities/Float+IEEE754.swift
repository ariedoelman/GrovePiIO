//
//  Float+IEEE754.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 15-01-17.
//
//

import Foundation

public extension Float {
  public init(ieee754LittleEndianBytes fbs: [UInt8], offset i: Int = 0) {
    self.init(bitPattern: (UInt32(fbs[i+3]) << 24) | (UInt32(fbs[i+2]) << 16) | (UInt32(fbs[i+1]) << 8) | UInt32(fbs[i]))
  }
}

