//
//  AnyGrovePiPortLabel.swift
//  GrovePiIO
//
//  Created by Arie Doelman on 21-01-17.
//
//

import Foundation

public final class AnyGrovePiPortLabel: GrovePiPortLabel {
  private let box: _AnyGrovePiPortLabelBoxBase
  public var name: String { return box.name }
  public var type: PortType { return box.type }
  public var id: UInt8 { return box.id }
  public var hashValue: Int { return box.hashValue }
  public var description: String { return box.description }

  public init<PL: GrovePiPortLabel>(_ base: PL) {
    if let any = base as? AnyGrovePiPortLabel {
      self.box = any.box
    } else {
      self.box = _AnyGrovePiPortLabelBox(base)
    }
  }

  public static func ==(lhs: AnyGrovePiPortLabel, rhs: AnyGrovePiPortLabel) -> Bool {
    return lhs.box.equals(rhs.box)
  }
}

private final class _AnyGrovePiPortLabelBox<PL: GrovePiPortLabel>: _AnyGrovePiPortLabelBoxBase {
  let base: PL
  override var name: String { return base.name }
  override var type: PortType { return base.type }
  override var id: UInt8 { return base.id }
  override var hashValue: Int { return base.hashValue }
  override var description: String { return base.description }

  init(_ base: PL) {
    self.base = base
  }

  override func equals(_ rhs: _AnyGrovePiPortLabelBoxBase) -> Bool {
    guard let rhsBox = rhs as? _AnyGrovePiPortLabelBox else {
      return false
    }
    return base == rhsBox.base
  }
}

private class _AnyGrovePiPortLabelBoxBase: GrovePiPortLabel {
  var name: String { fatalError()}
  var type: PortType { fatalError()}
  var id: UInt8 { fatalError() }
  var hashValue: Int { fatalError() }
  var description: String { fatalError() }

  func equals(_ rhs: _AnyGrovePiPortLabelBoxBase) -> Bool { fatalError() }

  static func ==(lhs: _AnyGrovePiPortLabelBoxBase, rhs: _AnyGrovePiPortLabelBoxBase) -> Bool { fatalError() }
}
