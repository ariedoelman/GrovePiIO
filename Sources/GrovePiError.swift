//
//  GrovePiError.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

import Foundation

public enum GrovePiError: Error {
  case OpenError(osError: Int32)
  case IOError(osError: Int32)
  case AlreadyOccupiedPort(portDescription: String)
  case UnsupportedPortTypeForUnit(unitDescription: String, portTypeDescription: String)
}

