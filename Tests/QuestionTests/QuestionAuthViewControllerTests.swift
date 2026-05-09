import XCTest
@testable import Question

final class QuestionAuthViewControllerTests: XCTestCase {
    func testLoopbackCallbackURLIsUsedForHatenaOAuth() {
        let callbackURL = QuestionBookmarkManager.callbackURL

        XCTAssertEqual(callbackURL.scheme, "http")
        XCTAssertEqual(callbackURL.host, "localhost")
        XCTAssertEqual(callbackURL.path, "/oauth-callback")
    }

    func testCallbackURLMatchesWhenHatenaAddsOAuthParameters() {
        let url = URL(string: "http://localhost/oauth-callback?oauth_token=token&oauth_verifier=verifier")!

        XCTAssertTrue(QuestionAuthViewController.isOAuthCallbackURL(url))
    }

    func testCallbackURLDoesNotUsePrefixMatching() {
        let url = URL(string: "http://localhost/oauth-callback-extra?oauth_token=token&oauth_verifier=verifier")!

        XCTAssertFalse(QuestionAuthViewController.isOAuthCallbackURL(url))
    }

    func testCallbackURLDoesNotMatchExternalHost() {
        let url = URL(string: "https://example.com/hatena?oauth_token=token&oauth_verifier=verifier")!

        XCTAssertFalse(QuestionAuthViewController.isOAuthCallbackURL(url))
    }
}
