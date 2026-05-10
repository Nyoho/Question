//
//  QuestionAuthViewController.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/8.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Cocoa
import WebKit
import OAuthSwift

public class QuestionAuthViewController: NSViewController, OAuthSwiftURLHandlerType, WKNavigationDelegate, WKUIDelegate {

    var webView: WKWebView!
    private var actionBarView: NSView!
    private var statusLabel: NSTextField!
    private var retryButton: NSButton!
    private var cancelButton: NSButton!
    var oauthURL: URL?
    var onRetryRequested: (() -> Void)?
    private var postLoginAuthorizationReloadCount = 0

    public static func loadFromNib() -> QuestionAuthViewController {
        QuestionAuthViewController(nibName: "QuestionAuthViewController", bundle: Bundle.module)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configureActionBar()

        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: actionBarView.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

    }
    
    public func handle(_ url: URL) {
        oauthURL = url
        postLoginAuthorizationReloadCount = 0
        statusLabel.stringValue = Self.localized("auth_status_sign_in")
        setRetryButtonVisible(false)
        webView.load(URLRequest(url: url))
    }

    public func webView(_ sender: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = sender.url {
            if Self.isOAuthCallbackURL(url) {
                OAuthSwift.handle(url: url)
            } else if Self.isHatenaPostLoginLandingURL(url) {
                reloadAuthorizationURLAfterHatenaLogin()
            }
            inspectForInvalidTokenPage(in: sender, url: url)
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, Self.isOAuthCallbackURL(url) {
            OAuthSwift.handle(url: url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    private func configureActionBar() {
        actionBarView = NSView()
        actionBarView.translatesAutoresizingMaskIntoConstraints = false
        actionBarView.wantsLayer = true
        actionBarView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.addSubview(actionBarView)

        statusLabel = NSTextField(labelWithString: Self.localized("auth_status_sign_in"))
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.maximumNumberOfLines = 1

        retryButton = NSButton(title: Self.localized("auth_retry_button"), target: self, action: #selector(retryAuthentication(_:)))
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.bezelStyle = .rounded
        retryButton.keyEquivalent = "\r"
        retryButton.isHidden = true
        retryButton.isEnabled = false

        cancelButton = NSButton(title: Self.localized("auth_cancel_button"), target: self, action: #selector(cancelAuthentication(_:)))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"

        actionBarView.addSubview(statusLabel)
        actionBarView.addSubview(retryButton)
        actionBarView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            actionBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            actionBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            actionBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            actionBarView.heightAnchor.constraint(equalToConstant: 52),

            statusLabel.leftAnchor.constraint(equalTo: actionBarView.leftAnchor, constant: 16),
            statusLabel.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor),
            statusLabel.rightAnchor.constraint(lessThanOrEqualTo: retryButton.leftAnchor, constant: -12),

            retryButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor),
            retryButton.rightAnchor.constraint(equalTo: actionBarView.rightAnchor, constant: -16),

            cancelButton.centerYAnchor.constraint(equalTo: actionBarView.centerYAnchor),
            cancelButton.rightAnchor.constraint(equalTo: retryButton.leftAnchor, constant: -8)
        ])
    }

    @objc private func retryAuthentication(_ sender: Any?) {
        statusLabel.stringValue = Self.localized("auth_status_retrying")
        setRetryButtonVisible(true, enabled: false)
        guard let onRetryRequested = onRetryRequested else {
            showAuthenticationError()
            return
        }

        onRetryRequested()
    }

    private func inspectForInvalidTokenPage(in webView: WKWebView, url: URL) {
        guard Self.isHatenaOAuthAuthorizeURL(url) else { return }

        webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { [weak self] result, _ in
            guard let text = result as? String,
                  Self.containsInvalidOAuthTokenMessage(text) else {
                return
            }

            self?.showAuthenticationError(message: Self.localized("auth_status_token_rejected"))
        }
    }

    private func reloadAuthorizationURLAfterHatenaLogin() {
        guard postLoginAuthorizationReloadCount == 0, let oauthURL = oauthURL else {
            showAuthenticationError()
            return
        }

        postLoginAuthorizationReloadCount += 1
        statusLabel.stringValue = Self.localized("auth_status_continuing")
        webView.load(URLRequest(url: oauthURL, cachePolicy: .reloadIgnoringLocalCacheData))
    }

    func showAuthenticationError(message: String = QuestionAuthViewController.localized("auth_status_failed")) {
        DispatchQueue.main.async {
            self.statusLabel?.stringValue = message
            self.setRetryButtonVisible(true)
        }
    }

    private func setRetryButtonVisible(_ visible: Bool, enabled: Bool = true) {
        retryButton?.isHidden = !visible
        retryButton?.isEnabled = visible && enabled
        retryButton?.keyEquivalent = visible && enabled ? "\r" : ""
    }

    static func isOAuthCallbackURL(_ url: URL, callbackURL: URL = QuestionBookmarkManager.callbackURL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            return false
        }

        return urlComponents.scheme == callbackComponents.scheme
            && urlComponents.host == callbackComponents.host
            && urlComponents.port == callbackComponents.port
            && urlComponents.path == callbackComponents.path
    }

    static func isHatenaOAuthAuthorizeURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        return components.scheme == "https"
            && components.host == "www.hatena.ne.jp"
            && components.path == "/oauth/authorize"
    }

    static func isHatenaPostLoginLandingURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == "www.hatena.ne.jp" else {
            return false
        }

        let queryContainsOAuthReturnLocation = components.queryItems?.contains { item in
            item.name.contains("/oauth/") || (item.value?.contains("/oauth/") ?? false)
        } ?? false

        return !components.path.contains("/oauth/")
            && !queryContainsOAuthReturnLocation
    }

    static func containsInvalidOAuthTokenMessage(_ text: String) -> Bool {
        text.contains("トークンが不正です")
            || text.localizedCaseInsensitiveContains("invalid token")
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: Bundle.module, comment: "")
    }
    
    public func clearCookiesAndSessions(completion: (() -> Void)? = nil) {
        let dataTypes = Set([WKWebsiteDataTypeCookies,
                             WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage,
                             WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            completion?()
        }
    }
    
    @objc public func close(_ sender: Any?) {
        let window = view.window
        let shouldCloseWindow = presentingViewController == nil && parent == nil

        webView?.stopLoading()
        onRetryRequested = nil
        dismiss(self)
        if shouldCloseWindow {
            window?.close()
        }
    }

    @objc private func cancelAuthentication(_ sender: Any?) {
        close(sender)
    }

    public override func cancelOperation(_ sender: Any?) {
        cancelAuthentication(sender)
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
