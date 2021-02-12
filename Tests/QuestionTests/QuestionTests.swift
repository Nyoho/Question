import XCTest
@testable import Question

final class QuestionTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Question().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
