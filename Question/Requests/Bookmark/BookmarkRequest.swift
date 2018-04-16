//
//  BookmarkRequest.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public struct GetBookmarkRequest: QuestionRequest {
    public typealias Response = Bookmark
    
    public let url: URL

    public var queryItems: [String:String] {
        return ["url": url.absoluteString]
    }

    public init(url: URL) {
        self.url = url
    }

    public var method: HTTPMethod {
        return .get
    }
    
    public var path: String {
        return "/my/bookmark"
    }
}

