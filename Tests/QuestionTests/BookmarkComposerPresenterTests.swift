import XCTest
@testable import Question

final class BookmarkComposerPresenterTests: XCTestCase {
    func testUnauthorizedThrows() {
        let presenter = BookmarkComposerPresenter(isAuthorized: { false }, viewControllerFactory: { QuestionBookmarkViewController(nibName: nil, bundle: nil) })
        let url = URL(string: "https://example.com/test")!
        XCTAssertThrowsError(try presenter.makeViewController(permalink: url)) { error in
            XCTAssertEqual(error as? BookmarkComposerPresenter.Error, .unauthorized)
        }
    }
    
    func testPresenterConfiguresViewController() throws {
        let expectedURL = URL(string: "https://example.com/entry")!
        let expectedTitle = "Sample"
        let expectedCount = "42 users"
        let stub = StubBookmarkViewController(nibName: nil, bundle: nil)
        let presenter = BookmarkComposerPresenter(isAuthorized: { true }, viewControllerFactory: { stub })
        let controller = try presenter.makeViewController(permalink: expectedURL, title: expectedTitle, bookmarkCountText: expectedCount)
        XCTAssertTrue(controller === stub)
        XCTAssertEqual(stub.configuredURL, expectedURL)
        XCTAssertEqual(stub.configuredTitle, expectedTitle)
        XCTAssertEqual(stub.configuredUsersCount, expectedCount)
    }
}

private final class StubBookmarkViewController: QuestionBookmarkViewController {
    private(set) var configuredURL: URL?
    private(set) var configuredTitle: String?
    private(set) var configuredUsersCount: String?
    
    override func configure(permalink: URL, title: String? = nil, bookmarkCountText: String? = nil) {
        configuredURL = permalink
        configuredTitle = title
        configuredUsersCount = bookmarkCountText
        super.configure(permalink: permalink, title: title, bookmarkCountText: bookmarkCountText)
    }
}
