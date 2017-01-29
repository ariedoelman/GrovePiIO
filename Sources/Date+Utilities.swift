//
//  Date+Utilities.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 29-01-17.
//
//

import Foundation

extension Date {
  public var hhmmssSSS: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss.SSS"
    return dateFormatter.string(from: self)
  }

  public static var hhmmssSSS: String {
    return Date().hhmmssSSS
  }
}
