//
//  UnitHumidity.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 29-01-17.
//
//

import Foundation

@available(OSX 10.12, *)
public final class UnitHumidity: Dimension {
  static let percentage = UnitHumidity(symbol: "%", converter: UnitConverterLinear(coefficient: 1.0))

  override public class func baseUnit() -> Self {
    return autocast(self.percentage)
  }
}
