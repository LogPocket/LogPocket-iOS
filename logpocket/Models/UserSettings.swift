//
//  UserSettings.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation

struct UserSettings: Codable {
    var tistoryURL: String?
    var velogURL: String?
    var hasCompletedOnboarding: Bool = false
    var preferredPlatform: BlogPlatform?
    
    var hasTistory: Bool {
        tistoryURL != nil && !tistoryURL!.isEmpty
    }
    
    var hasVelog: Bool {
        velogURL != nil && !velogURL!.isEmpty
    }
    
    var hasAnyPlatform: Bool {
        hasTistory || hasVelog
    }
}
