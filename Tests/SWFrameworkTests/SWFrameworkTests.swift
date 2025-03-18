import XCTest
@testable import SWFramework

final class SWFrameworkTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNotNil(SWFramework.shared)
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
} 