//
//  QuestionResponse.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public protocol QuestionResponse {
    init(response: HTTPURLResponse, json: Data) throws
}

extension QuestionResponse where Self: Decodable {
    public init(response: HTTPURLResponse, json: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self = try decoder.decode(Self.self, from: json)
    }
}

