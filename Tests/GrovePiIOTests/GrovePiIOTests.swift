import XCTest
@testable import GrovePiIO

class GrovePiIOTests: XCTestCase {
  func testConnectBus() throws {
    let _ = try GrovePiBus.connectBus()
    //        XCTAssertEqual(GrovePiBus.text, "Hello, World!")
  }

  func testConnectTemperatureAndHumiditySensor() throws {
    let bus = try GrovePiBus.connectBus()
    defer { try? GrovePiBus.disconnectBus() }
    let blueModel = DHTModuleType.blue
    let deltaT: TimeInterval = 60
    let sensor = try bus.connectTemperatureAndHumiditySensor(to: .D2, moduleType: blueModel, sampleTimeInterval: deltaT)
    XCTAssertEqual(sensor.portLabel, .D2)
    XCTAssertEqual(sensor.inputUnit.ioMode, .input)
    XCTAssertEqual(sensor.inputUnit.moduleType, blueModel)
    XCTAssertEqual(sensor.inputUnit.supportedPortTypes, [.digital])
    XCTAssertEqual(sensor.inputUnit.sampleTimeInterval, deltaT)
    _ = try sensor.readValue()
    try sensor.disconnect()
    do {
      _ = try sensor.readValue()
      XCTFail()
    } catch _ as GrovePiError {
    }
  }

  func testInputChangedValueDelegate() throws {
    let bus = try GrovePiBus.connectBus()
    let sensor = try bus.connectTemperatureAndHumiditySensor(to: .D2)
    let reporter = InputValueChangedReporter<TemperatureAndHumidity>(reportNewInput: {
      let whenDate = Date(timeIntervalSinceReferenceDate: $1)
      print("New data read \($0) at \(whenDate)")
    })
    XCTAssertEqual(sensor.delegatesCount, 0)
    try sensor.addValueChangedDelegate(reporter)
    XCTAssertEqual(sensor.delegatesCount, 1)
    try sensor.removeValueChangedDelegate(reporter)
    XCTAssertEqual(sensor.delegatesCount, 0)
  }


//  static var allTests : [(String, (GrovePiIOTests) -> () throws -> Void)] {
//    return [
//      ("testConnectBus", testConnectBus),
//    ]
//  }
}
