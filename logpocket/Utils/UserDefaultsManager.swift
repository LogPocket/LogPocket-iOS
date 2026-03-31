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
    private let defaults: UserDefaults
    
    private init() {
        if let suiteDefaults = UserDefaults(suiteName: AppGroupConfig.suiteName) {
            defaults = suiteDefaults
            migrateFromStandardDefaultsIfNeeded()
        } else {
            defaults = .standard
        }
    }
    
    func saveSettings(_ settings: UserSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: userSettingsKey)
        }
    }
    
    func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: userSettingsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }
    
    func clearSettings() {
        defaults.removeObject(forKey: userSettingsKey)
    }
    
    private func migrateFromStandardDefaultsIfNeeded() {
        let sharedExists = defaults.data(forKey: userSettingsKey) != nil
        guard !sharedExists else { return }
        
        if let legacy = UserDefaults.standard.data(forKey: userSettingsKey) {
            defaults.set(legacy, forKey: userSettingsKey)
        }
    }
}
