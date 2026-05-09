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
    var oauthURL: URL?
    var onLoginCompleted: (() -> Void)?

    public static func loadFromNib() -> QuestionAuthViewController {
        QuestionAuthViewController(nibName: "QuestionAuthViewController", bundle: Bundle.module)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

    }
    
    public func handle(_ url: URL) {
        oauthURL = url
        webView.load(URLRequest(url: url))
    }

    public func webView(_ sender: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = sender.url {
            let u = url.absoluteString
            if Self.isOAuthCallbackURL(url) {
                OAuthSwift.handle(url: url)
            } else if url.host == "www.hatena.ne.jp" && !u.contains("/oauth/") {
                // ログイン後にトップページに飛ばされるようになった? そのときはOAuthフローを再開することに
                if let callback = onLoginCompleted {
                    onLoginCompleted = nil
                    callback()
                }
            }
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
    
    public func clearCookiesAndSessions(completion: (() -> Void)? = nil) {
        let dataTypes = Set([WKWebsiteDataTypeCookies,
                             WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage,
                             WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
            completion?()
        }
    }
    
    public func close(_ sender: Any?) {
        dismiss(self)
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
