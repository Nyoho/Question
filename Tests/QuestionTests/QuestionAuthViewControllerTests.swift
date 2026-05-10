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

    func testHatenaOAuthAuthorizeURLIsDetected() {
        let url = URL(string: "https://www.hatena.ne.jp/oauth/authorize?oauth_token=token")!

        XCTAssertTrue(QuestionAuthViewController.isHatenaOAuthAuthorizeURL(url))
    }

    func testNonHatenaOAuthAuthorizeURLIsNotDetected() {
        let url = URL(string: "https://example.com/oauth/authorize?oauth_token=token")!

        XCTAssertFalse(QuestionAuthViewController.isHatenaOAuthAuthorizeURL(url))
    }

    func testHatenaPostLoginLandingURLIsDetected() {
        let url = URL(string: "https://www.hatena.ne.jp/")!

        XCTAssertTrue(QuestionAuthViewController.isHatenaPostLoginLandingURL(url))
    }

    func testHatenaOAuthAuthorizeURLIsNotPostLoginLandingURL() {
        let url = URL(string: "https://www.hatena.ne.jp/oauth/authorize?oauth_token=token")!

        XCTAssertFalse(QuestionAuthViewController.isHatenaPostLoginLandingURL(url))
    }

    func testHatenaLoginPageWithOAuthReturnLocationIsNotPostLoginLandingURL() {
        let url = URL(string: "https://www.hatena.ne.jp/login?location=https%3A%2F%2Fwww.hatena.ne.jp%2Foauth%2Fauthorize%3Foauth_token%3Dtoken")!

        XCTAssertFalse(QuestionAuthViewController.isHatenaPostLoginLandingURL(url))
    }

    func testInvalidOAuthTokenMessageIsDetected() {
        XCTAssertTrue(QuestionAuthViewController.containsInvalidOAuthTokenMessage("トークンが不正です"))
        XCTAssertTrue(QuestionAuthViewController.containsInvalidOAuthTokenMessage("Invalid token"))
    }

    func testUnrelatedOAuthPageTextIsNotDetectedAsInvalidToken() {
        XCTAssertFalse(QuestionAuthViewController.containsInvalidOAuthTokenMessage("Authorize Question to access Hatena Bookmark"))
    }
}
