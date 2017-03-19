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
    var authorized = false
    
    var oauthswift = OAuth1Swift(
        consumerKey:     "consumerKey",
        consumerSecret:  "consumerSecret",
        requestTokenUrl: "https://www.hatena.com/oauth/initiate?scope=read_public,write_public",
        authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
        accessTokenUrl:  "https://www.hatena.com/oauth/token"
    )

    class func sharedManager() -> QuestionBookmarkManager {
        struct Static {
            static let instance = QuestionBookmarkManager()
        }
        return Static.instance
    }

    public func setConsumerKey(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
}
