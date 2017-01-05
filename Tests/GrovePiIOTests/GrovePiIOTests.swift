import XCTest
@testable import GrovePiIO

class GrovePiIOTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(GrovePiIO().text, "Hello, World!")
    }


    static var allTests : [(String, (GrovePiIOTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
