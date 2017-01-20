//
//  UInt16+BigEndian.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 16-01-17.
//
//

import Foundation

internal extension UInt16 {
  init(bigEndianBytes bytes: [UInt8], offset i: Int = 0) {
    self = (UInt16(bytes[i]) << 8) | UInt16(bytes[i+1])
  }
}
