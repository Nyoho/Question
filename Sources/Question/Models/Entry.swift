//
//  Entry.swift
//  Question
//
//  Created by 北䑓 如法 on 18/4/15.
//  Copyright © 2018年 北䑓 如法. All rights reserved.
//

import Foundation

public struct Entry: Decodable, QuestionResponse {
    public let title: String
    public let url: URL
    public let entryURL: URL
    public let count: UInt
    public let faviconURL: URL
    public let smartphoneAppEntryURL: URL?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case url
        case entryURL = "entry_url"
        case count
        case faviconURL = "favicon_url"
        case smartphoneAppEntryURL = "smartphone_app_entry_url"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decode(URL.self, forKey: .url)
        self.entryURL = try container.decode(URL.self, forKey: .entryURL)
        self.count = try container.decode(UInt.self, forKey: .count)
        self.faviconURL = try container.decode(URL.self, forKey: .faviconURL)
        
        if let urlString = try container.decodeIfPresent(String.self, forKey: .smartphoneAppEntryURL),
           let url = URL(string: urlString), !urlString.isEmpty {
            self.smartphoneAppEntryURL = url
        } else {
            self.smartphoneAppEntryURL = nil
        }
    }
}
