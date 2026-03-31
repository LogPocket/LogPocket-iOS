//
//  BlogPost.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation

struct BlogPost: Identifiable, Codable {
    let id: String
    let title: String
    let url: String
    let platform: BlogPlatform
    let publishedDate: Date?
}
