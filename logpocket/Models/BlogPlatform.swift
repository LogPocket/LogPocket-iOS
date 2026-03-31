//
//  BlogPlatform.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation

enum BlogPlatform: String, CaseIterable, Codable {
    case tistory = "Tistory"
    case velog = "Velog"
    
    var placeholder: String {
        switch self {
        case .tistory:
            return "https://mark7723.tistory.com/"
        case .velog:
            return "https://velog.io/@mark77234/posts"
        }
    }
    
    func isValidURL(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }
        
        switch self {
        case .tistory:
            return url.contains("tistory.com")
        case .velog:
            return url.contains("velog.io")
        }
    }
}
