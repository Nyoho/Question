//
//  Tag.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public struct Tag: Decodable, QuestionResponse {
    let count: UInt
    let modifiedEpoch: UInt
    let modifiedDatetime: Date
    let tag: String
    
    private enum CodingKeys: String, CodingKey {
        case count
        case modifiedEpoch = "modified_epoch"
        case modifiedDatetime = "modified_datetime"
        case tag
    }
}
