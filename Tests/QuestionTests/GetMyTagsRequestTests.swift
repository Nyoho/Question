import XCTest
@testable import Question

final class GetMyTagsRequestTests: XCTestCase {

    func testPath() {
        let request = GetMyTagsRequest()
        XCTAssertEqual(request.path, "/my/tags")
    }

    func testMethod() {
        let request = GetMyTagsRequest()
        XCTAssertEqual(request.method, .get)
    }

    func testQueryItemsIsEmpty() {
        let request = GetMyTagsRequest()
        XCTAssertTrue(request.queryItems.isEmpty)
    }

    func testResponseDecoding() throws {
        let json = """
        {
            "tags": [
                {
                    "count": 42,
                    "modified_epoch": 1709424000,
                    "modified_datetime": "2024-03-03T00:00:00Z",
                    "tag": "swift"
                },
                {
                    "count": 10,
                    "modified_epoch": 1712188800,
                    "modified_datetime": "2024-04-04T00:00:00Z",
                    "tag": "programming"
                }
            ]
        }
        """.data(using: .utf8)!

        let request = GetMyTagsRequest()
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = try request.response(from: json, urlResponse: response)
        XCTAssertEqual(result.tags.count, 2)
        XCTAssertEqual(result.tags[0].tag, "swift")
        XCTAssertEqual(result.tags[0].count, 42)
        XCTAssertEqual(result.tags[1].tag, "programming")
        XCTAssertEqual(result.tags[1].count, 10)
    }
}
