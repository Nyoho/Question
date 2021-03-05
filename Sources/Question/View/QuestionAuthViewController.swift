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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: self.view.frame, configuration: configuration)
//        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 400), configuration: configuration)
//        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        // topAnchor only available in version 10.11
//        [webView.topAnchor.constraint(equalTo: view.topAnchor),
//         webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//         webView.leftAnchor.constraint(equalTo: view.leftAnchor),
//         webView.rightAnchor.constraint(equalTo: view.rightAnchor)].forEach  {
//            anchor in
//            anchor.isActive = true
//        }  // end forEach

    }
    
    public func handle(_ url: URL) {
        print("url: \(url)")
        webView.load(URLRequest(url: url))
    }

    public func webView(_ sender: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = sender.url {
            print("did finish: \(url)")
            let u = url.absoluteString
            if u.hasPrefix("https://nyoho.jp/oauth/") {
                print("Arrived callback page")
                OAuthSwift.handle(url: url)
                self.dismiss(self)
            }
        }
    }
    
    public func clearCookiesAndSessions() {
        let dataTypes = Set([WKWebsiteDataTypeCookies,
                             WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage,
                             WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast, completionHandler: {})
    }
    
}
