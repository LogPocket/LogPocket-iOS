//
//  UserDefaultsManager.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let userSettingsKey = "userSettings"
    
    private init() {}
    
    func saveSettings(_ settings: UserSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userSettingsKey)
        }
    }
    
    func loadSettings() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: userSettingsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }
    
    func clearSettings() {
        UserDefaults.standard.removeObject(forKey: userSettingsKey)
    }
}
