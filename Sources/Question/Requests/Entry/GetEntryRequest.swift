//
//  GetEntryRequest.swift
//  Question
//
//  Created by 北䑓 如法 on 2024/04/03.
//  Copyright © 2024年 北䑓 如法. All rights reserved.
//

import Foundation

public struct GetEntryRequest: QuestionRequest {
    public typealias Response = Entry
    
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public var path: String { "/entry" }
    
    public var method: HTTPMethod { .get }
    
    public var queryItems: [String : Any] { ["url": url.absoluteString] }
}
