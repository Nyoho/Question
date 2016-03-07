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

public class QuestionBookmarkManager {
    var consumerKey = ""
    var consumerSecret = ""
    var authorized = false
    
    public static let sharedManager = QuestionBookmarkManager()

    public func setConsumerKey(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
}
