//
//  QuestionError.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public enum QuestionError: Error {
    case connectionError(Error)
    case responseParseError(Error)
    case apiError(Error)
    case httpStatus(code: Int, data: Data)
}

public struct QuestionAPIError: Error, Decodable {

}
