//
//  TagCompletionTests.swift
//  QuestionTests
//

import XCTest
@testable import Question

final class TagCompletionTests: XCTestCase {

    func testExtractTagPrefixAtCursor_withOpenBracket() {
        let helper = TagCompletionHelper()
        // "[mac" with cursor at end
        let result = helper.extractTagPrefix(from: "[mac", cursorPosition: 4)
        XCTAssertEqual(result?.prefix, "mac")
        XCTAssertEqual(result?.bracketPosition, 0)
    }

    func testExtractTagPrefixAtCursor_withOpenBracketOnly() {
        let helper = TagCompletionHelper()
        // "[" with cursor at end
        let result = helper.extractTagPrefix(from: "[", cursorPosition: 1)
        XCTAssertEqual(result?.prefix, "")
        XCTAssertEqual(result?.bracketPosition, 0)
    }

    func testExtractTagPrefixAtCursor_withTextBeforeBracket() {
        let helper = TagCompletionHelper()
        // "test [prog" with cursor at end
        let result = helper.extractTagPrefix(from: "test [prog", cursorPosition: 10)
        XCTAssertEqual(result?.prefix, "prog")
        XCTAssertEqual(result?.bracketPosition, 5)
    }

    func testExtractTagPrefixAtCursor_withClosedTag() {
        let helper = TagCompletionHelper()
        // "[mac]" with cursor at end - should return nil
        let result = helper.extractTagPrefix(from: "[mac]", cursorPosition: 5)
        XCTAssertNil(result)
    }

    func testExtractTagPrefixAtCursor_withMultipleTags() {
        let helper = TagCompletionHelper()
        // "[swift][mac" with cursor at end
        let result = helper.extractTagPrefix(from: "[swift][mac", cursorPosition: 11)
        XCTAssertEqual(result?.prefix, "mac")
        XCTAssertEqual(result?.bracketPosition, 7)
    }

    func testExtractTagPrefixAtCursor_noBracket() {
        let helper = TagCompletionHelper()
        // "just text" with cursor at end
        let result = helper.extractTagPrefix(from: "just text", cursorPosition: 9)
        XCTAssertNil(result)
    }

    func testExtractTagPrefixAtCursor_cursorInMiddle() {
        let helper = TagCompletionHelper()
        // "[mac] comment" with cursor after "]"
        let result = helper.extractTagPrefix(from: "[mac] comment", cursorPosition: 5)
        XCTAssertNil(result)
    }

    func testFilterTags_withPrefix() {
        let helper = TagCompletionHelper()
        let tags = [
            Tag(count: 10, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "macOS"),
            Tag(count: 5, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "machine-learning"),
            Tag(count: 3, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "swift"),
            Tag(count: 1, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "programming")
        ]

        let result = helper.filterTags(tags, prefix: "mac")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].tag, "macOS")
        XCTAssertEqual(result[1].tag, "machine-learning")
    }

    func testFilterTags_emptyPrefix() {
        let helper = TagCompletionHelper()
        let tags = [
            Tag(count: 10, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "swift"),
            Tag(count: 5, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "mac")
        ]

        let result = helper.filterTags(tags, prefix: "")
        XCTAssertEqual(result.count, 2)
    }

    func testFilterTags_caseInsensitive() {
        let helper = TagCompletionHelper()
        let tags = [
            Tag(count: 10, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "MacOS"),
            Tag(count: 5, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "swift")
        ]

        let result = helper.filterTags(tags, prefix: "mac")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].tag, "MacOS")
    }

    func testFilterTags_sortedByCount() {
        let helper = TagCompletionHelper()
        let tags = [
            Tag(count: 1, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "mac-mini"),
            Tag(count: 10, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "macOS"),
            Tag(count: 5, modifiedEpoch: 0, modifiedDatetime: Date(), tag: "macbook")
        ]

        let result = helper.filterTags(tags, prefix: "mac")
        XCTAssertEqual(result[0].tag, "macOS")
        XCTAssertEqual(result[1].tag, "macbook")
        XCTAssertEqual(result[2].tag, "mac-mini")
    }
}
