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
    
    public var queryItems: [String:Any] {
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

public struct PostBookmarkRequest: QuestionRequest {
    public typealias Response = Bookmark
    
    public var url: URL
    public var comment: String
    public var tags: [String] = [] // max 10
    public var postTwitter: Bool
    public var postFacebook: Bool = false
    public var postMixi: Bool = false
    public var postEvernote : Bool = false
    public var sendMail:Bool = false
    public var isPrivate: Bool
    
    public var queryItems: [String:Any] {
        return [
            "url": url.absoluteString,
            "comment": comment,
            "post_twitter": questionBool(postTwitter),
            "post_facebook": questionBool(postFacebook),
            "post_mixi": questionBool(postMixi),
            "post_evernote": questionBool(postEvernote),
            "send_mail": questionBool(sendMail),
            "private": questionBool(isPrivate)
        ]
    }
    
    public init(url: URL,
                comment: String = "",
                tags: [String] = [],
                postTwitter: Bool = false,
                postFacebook: Bool = false,
                postMixi: Bool = false,
                postEvernote: Bool = false,
                sendMail: Bool = false,
                isPrivate: Bool = false
                ) {
        self.url = url
        self.comment = comment
        self.tags = tags
        self.postTwitter = postTwitter
        self.postFacebook = postFacebook
        self.postMixi = postMixi
        self.postEvernote = postEvernote
        self.sendMail = sendMail
        self.isPrivate = isPrivate
    }

    public var method: HTTPMethod {
        return .post
    }
    
    public var path: String {
        return "/my/bookmark"
    }
}

public struct DeleteBookmarkRequest: QuestionRequest {
    public typealias Response = EmptyResponse
    
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public var method: HTTPMethod { .delete }
    public var path: String { "/my/bookmark" }
    public var queryItems: [String: Any] { ["url": url.absoluteString] }
    
    public func response(from data: Data, urlResponse: URLResponse) throws -> Response {
        if let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode,
           !(200..<300).contains(statusCode) {
            throw QuestionError.httpStatus(code: statusCode, data: data)
        }
        return EmptyResponse()
    }
}

public struct EmptyResponse: Decodable {}
