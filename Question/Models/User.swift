//
//  User.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public struct User: Decodable, QuestionResponse {
    let name: String
    let isPlususer: Bool
    let isPrivate: Bool
    let isOAuthTwitter: Bool
    let isOAuthEvernote: Bool
    let isOAuthFacebook: Bool
    let isOAuthMixiCheck: Bool
    
    private enum CodingKeys: String, CodingKey {
        case name
        case isPlususer = "plususer"
        case isPrivate = "private"
        case isOAuthTwitter = "is_oauth_twitter"
        case isOAuthEvernote = "is_oauth_evernote"
        case isOAuthFacebook = "is_oauth_facebook"
        case isOAuthMixiCheck = "is_oauth_mixi_check"
    }
}
