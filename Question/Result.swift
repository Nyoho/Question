//
//  Result.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public enum Result<T, Error: Swift.Error> {
    case success(T)
    case failure(Error)
}

