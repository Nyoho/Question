//
//  Bookmark.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public struct Bookmark: Decodable, QuestionResponse {
    public let comment: String
    public let commentRaw: String
    public let createdDatetime: Date
    public let createdEpoch: UInt
    public let user: String
    public let permalink: URL
    public let isPrivate: Bool
    public let tags: [String]
    public let eid: String
    public let favorites: [Bookmark]?
    
    private enum CodingKeys: String, CodingKey {
        case comment
        case commentRaw = "comment_raw"
        case createdDatetime = "created_datetime"
        case createdEpoch = "created_epoch"
        case user
        case permalink
        case isPrivate = "private"
        case tags
        case eid
        case favorites
    }
}
