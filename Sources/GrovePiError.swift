//
//  GrovePiError.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 14-01-17.
//
//

#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif
import Foundation

public enum GrovePiError: Error {
  case OpenError(osError: POSIXErrorCode)
  case IOError(osError: POSIXErrorCode)
  case CloseError(osError: POSIXErrorCode)
  case AlreadyOccupiedPort(portDescription: String)
  case UnsupportedPortTypeForUnit(unitDescription: String, portTypeDescription: String)
  case DisconnectedBus
  case DisconnectedPort(portDescription: String)
}

extension POSIXErrorCode {
  static func fromErrno() -> POSIXErrorCode {
    return POSIXErrorCode(rawValue: errno) ?? POSIXErrorCode.ENOTRECOVERABLE // choosen the last one in case unknown errno
  }
}

