//
//  QuestionRequest.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case head = "HEAD"
    case delete = "DELETE"
    case patch = "PATCH"
    case trace = "TRACE"
    case options = "OPTIONS"
    case connect = "CONNECT"
}

public protocol QuestionRequest {
    associatedtype Response: Decodable
    
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [String:Any] { get } // not [URLQueryItem]
    func response(from data: Data, urlResponse: URLResponse) throws -> Response
}

public extension QuestionRequest {
    var baseURL: URL {
        return URL(string: "https://bookmark.hatenaapis.com/rest/1")!
    }
    
    func response(from data: Data, urlResponse: URLResponse) throws -> Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if case (200..<300)? = (urlResponse as? HTTPURLResponse)?.statusCode {
            return try decoder.decode(Response.self, from: data)
        } else {
            throw try decoder.decode(QuestionAPIError.self, from: data)
        }
    }
    
    func questionBool(_ b: Bool) -> Int {
        return b ? 1 : 0
    }
}
