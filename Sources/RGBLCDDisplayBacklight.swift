//
//  LCDRGBDisplay.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 04-02-17.
//
//

import Foundation

public struct RGBColor: CustomStringConvertible {
  let red: UInt8
  let green: UInt8
  let blue: UInt8

  public var description: String { return "RGBColor(red: \(red), green: \(green), blue: \(blue))" }

  public init(red: UInt8 = 0, green: UInt8 = 0, blue: UInt8 = 0) {
    self.red = red
    self.green = green
    self.blue = blue
  }
}

public struct DisplayText: GrovePiOutputValueType, CustomStringConvertible {
  let rgbColor: RGBColor?
  let text: String?
  let noRefresh: Bool

  public var description: String { return "DisplayText(rgbColor: \(rgbColor), text: \(text), noRefresh: \(noRefresh))" }

  private init(rgbColor: RGBColor?, text: String?, noRefresh: Bool) {
    self.rgbColor = rgbColor
    self.text = text
    self.noRefresh = noRefresh
  }

  /// Color only change
  public init(rgbColor: RGBColor) {
    self.init(rgbColor: rgbColor, text: nil, noRefresh: false)
  }

  /// Text only, with/without refresh
  public init(text: String, noRefresh: Bool = false) {
    self.init(rgbColor: nil, text: text, noRefresh: noRefresh)
  }

  /// RGBColor and Text, with/without refresh
  public init(rgbColor: RGBColor, text: String, noRefresh: Bool = false) {
    self.init(rgbColor: rgbColor, text: text, noRefresh: noRefresh)
  }
}

public enum BacklightType: String {
  case negative, positive
}

public struct RGB_LCD_DisplayUnit: GrovePiOutputUnit {
  public let name: String
  public let supportedPortTypes = [PortType.i2c]
  public let backlightType: BacklightType

  public var description: String {
    return "\(name): supported port type(s): \(supportedPortTypes)"
  }

  public init(backlightType: BacklightType = .negative) {
    self.backlightType = backlightType
    self.name = "RGB LCD Display (\(backlightType.rawValue) backlight)"
  }
}

// MARK: - Public extensions

public extension GrovePiBus {
  func connectRGB_LCD_Display(portLabel: GrovePiI2CPortLabel, backlightType: BacklightType = .negative)
    throws -> RGB_LCD_DisplayDestination {
      let actuatorUnit = RGB_LCD_DisplayUnit(backlightType: backlightType)
      let outputProtocol = RGB_LCD_DisplayProtocol()
      return RGB_LCD_DisplayDestination(try busDelegate.connect(portLabel: portLabel, to: actuatorUnit, using: outputProtocol))
  }
}

// MARK: - Convenience alternative for AnyGrovePiOutputDestination

public final class RGB_LCD_DisplayDestination: GrovePiOutputDestination {
  private var delegate: AnyGrovePiOutputDestination<GrovePiI2CPortLabel, RGB_LCD_DisplayUnit, DisplayText>
  public var portLabel: GrovePiI2CPortLabel { return delegate.portLabel }
  public var outputUnit: RGB_LCD_DisplayUnit { return delegate.outputUnit }

  public init(_ delegate: AnyGrovePiOutputDestination<GrovePiI2CPortLabel, RGB_LCD_DisplayUnit, DisplayText>) {
    self.delegate = delegate
  }

  public func writeValue(_ value: DisplayText) throws {
    try delegate.writeValue(value)
  }

  public func connect() throws {
    try delegate.connect()
  }

  public func disconnect() throws {
    try delegate.disconnect()
  }
}

// MARK: - private implementations

private struct RGB_LCD_DisplayProtocol: GrovePiOutputProtocol {
  var writeCommand: WriteCommandType { return .other }

  func otherWriteCommandImplementation<PL: GrovePiPortLabel>(for outputValue: DisplayText, to arduinoBus: GrovePiArduinoBus, at _: PL) throws {
    if let rgbColor = outputValue.rgbColor {
      try arduinoBus.write(rgbColor: rgbColor)
    }
    if let text = outputValue.text {
      try arduinoBus.write(text: text, noRefresh: outputValue.noRefresh)
    }
  }

  func convert(outputValue: DisplayText) -> [UInt8] {
    fatalError()
  }
}

fileprivate extension GrovePiArduinoBus {
  var displayRGBAddress: UInt8 { return 0x62 }
  var displayTextAddress: UInt8 { return 0x3E }
  var textCommand: UInt8 { return 0x80 }

  func write(rgbColor: RGBColor) throws {
    try setAddress(displayRGBAddress)
    try writeByte(0, val: 0)
    try writeByte(1, val: 0)
    try writeByte(0x08, val: 0xAA)
    try writeByte(4, val: rgbColor.red)
    try writeByte(3, val: rgbColor.green)
    try writeByte(2, val: rgbColor.blue)
  }

  func write(text: String, noRefresh: Bool) throws {
    try setAddress(displayTextAddress)
    try writeByte(textCommand, val: noRefresh ? 0x02 : 0x01)
    usleep(50_000)
    try writeByte(textCommand, val: 0x0C) // display on, no cursor
    try writeByte(textCommand, val: 0x28) // 2 lines
    usleep(50_000)
    guard let charBytes: [Int8] = text.cString(using: String.Encoding.isoLatin1) else {
      throw GrovePiError.UnsupportedOutputValue(outputValueDescription: "Text \(text) contains non-ISO LATIN 1 characters")
    }
    var column = 0
    var row = 0
    for charByte in charBytes {
      if charByte == 0x0A /* \n or newline */ || column == 16 {
        if row == 1 {
          break
        }
        try writeByte(textCommand, val: 0xC0) // new line
        row += 1
        column = 0
        if charByte == 0x0A {
          continue
        }
      }
      try writeByte(0x40, val: UInt8(charByte))
      column += 1
    }
  }

}

