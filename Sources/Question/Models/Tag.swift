//
//  Tag.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public struct Tag: Decodable, QuestionResponse {
    public let count: UInt
    public let modifiedEpoch: UInt
    public let modifiedDatetime: Date
    public let tag: String

    public init(count: UInt, modifiedEpoch: UInt, modifiedDatetime: Date, tag: String) {
        self.count = count
        self.modifiedEpoch = modifiedEpoch
        self.modifiedDatetime = modifiedDatetime
        self.tag = tag
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case modifiedEpoch = "modified_epoch"
        case modifiedDatetime = "modified_datetime"
        case tag
    }
}
