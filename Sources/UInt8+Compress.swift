//
//  UInt8+Compress.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 22-01-17.
//
//

import Foundation

public extension UInt8 {

  /// Compress range 0..<1024 to range 0..<256, by dividing by 4
  public init(compressFromRange1024 range: UInt16) {
    self = UInt8(truncatingBitPattern: range << 2)
  }
}
