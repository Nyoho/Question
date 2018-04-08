//
//  QuestionBookmarkManager.swift
//  Question
//
//  Created by 北䑓 如法 on 16/3/1.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import OAuthSwift
import KeychainAccess

private let questionBookmarkManagerInstance: QuestionBookmarkManager = QuestionBookmarkManager()

public class QuestionBookmarkManager {
    var consumerKey = ""
    var consumerSecret = ""
    public var authorized = false
    let keychain = Keychain(service: "jp.nyoho.Question")
    var username = ""
    var displayName = ""
    
    var oauthswift = OAuth1Swift(
        consumerKey:     "consumerKey",
        consumerSecret:  "consumerSecret",
        requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public",
        authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
        accessTokenUrl:  "https://www.hatena.com/oauth/token"
    )

    public class var shared: QuestionBookmarkManager {
        struct Static {
            static let instance = QuestionBookmarkManager()
        }
        return Static.instance
    }

    public func setConsumerKey(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        oauthswift = OAuth1Swift(
            consumerKey:     consumerKey,
            consumerSecret:  consumerSecret,
            requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public",
            authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
            accessTokenUrl:  "https://www.hatena.com/oauth/token"
        )
        checkAuthed()
    }
    
    func checkAuthed() {
        if let token = keychain["oauthToken"], let tokenSecret = keychain["oauthTokenSecret"] {
            oauthswift.client.credential.oauthToken = token
            oauthswift.client.credential.oauthTokenSecret = tokenSecret
            authorized = true
        }
    }
    public func auth(viewController: QuestionAuthViewController) {
        oauthswift.authorizeURLHandler = viewController
        oauthswift.authorize(
            withCallbackURL: URL(string: "https://nyoho.jp/oauth/")!,
            success: { credential, response, parameters in
                print("Authentification succeeded.")
                if let n = parameters["url_name"] as? String {
                    self.username = n
                }
                if let n = parameters["display_name"] as? String {
                    self.displayName = n
                }
                self.keychain["oauthToken"] = credential.oauthToken
                self.keychain["oauthTokenSecret"] = credential.oauthTokenSecret
                self.keychain["url_name"] = self.username
                self.keychain["display_name"] = self.displayName
                self.authorized = true
        },
            failure: { error in
                print("Authentification failed.")
                print(error.localizedDescription)
        })
    }

    public func signOut() {
        keychain["oauthToken"] = nil
        keychain["oauthTokenSecret"] = nil
        keychain["url_name"] = nil
        keychain["display_name"] = nil
        if let vc = QuestionAuthViewController.init(nibName: "QuestionAuthViewController", bundle: Bundle.main) {
            vc.clearCookiesAndSessions()
        }
        oauthswift.client.credential.oauthToken = ""
        oauthswift.client.credential.oauthTokenSecret = ""
        authorized = false
    }
    
    public func getMyBookmark(_ sender: Any) {
//        print("token:")
//        print(oauthswift.client.credential.oauthToken)
//        print("token secret:")
//        print(oauthswift.client.credential.oauthTokenSecret)
        
        oauthswift.client.get(
            "http://api.b.hatena.ne.jp/1/my/bookmark",
            parameters: ["url": "http://www.slideshare.net/okapies/reactive-architecture-20160218-58403521"],
            headers: nil,
            success: { response in
                let dataString = String(data: response.data, encoding: String.Encoding.utf8)
                print("\(String(describing: dataString))")
        }, failure: { error in
            print(error)
        })
    }
    
}
