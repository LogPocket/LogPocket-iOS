//
//  UserDefaultsManager.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
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
            defaults.set(encoded, forKey: AppGroupConfig.userSettingsKey)
            reloadWidgetTimelines()
        }
    }
    
    func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: AppGroupConfig.userSettingsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }
    
    func saveLatestPosts(_ posts: [BlogPost], for platform: BlogPlatform) {
        let latestPosts = Array(posts.prefix(40))
        guard !latestPosts.isEmpty else { return }
        
        let cacheItems = latestPosts.map { post in
            WidgetCachedPost(
                id: post.id,
                title: post.title,
                url: post.url,
                publishedDate: post.publishedDate,
                summary: post.summary
            )
        }
        
        guard let encoded = try? JSONEncoder().encode(cacheItems) else { return }
        
        defaults.set(encoded, forKey: cachedPostsKey(for: platform))
        defaults.set(Date(), forKey: cachedUpdatedAtKey(for: platform))
        
        reloadWidgetTimelines()
    }
    
    func clearLatestPosts(for platform: BlogPlatform, reloadWidget: Bool = true) {
        defaults.removeObject(forKey: cachedPostsKey(for: platform))
        defaults.removeObject(forKey: cachedUpdatedAtKey(for: platform))
        
        if reloadWidget {
            reloadWidgetTimelines()
        }
    }
    
    func clearSettings() {
        defaults.removeObject(forKey: AppGroupConfig.userSettingsKey)
        defaults.removeObject(forKey: AppGroupConfig.widgetCachedPostsTistoryKey)
        defaults.removeObject(forKey: AppGroupConfig.widgetCachedPostsVelogKey)
        defaults.removeObject(forKey: AppGroupConfig.widgetCachedUpdatedAtTistoryKey)
        defaults.removeObject(forKey: AppGroupConfig.widgetCachedUpdatedAtVelogKey)
        defaults.removeObject(forKey: AppGroupConfig.widgetLargePostOffsetKey)
        defaults.removeObject(forKey: AppGroupConfig.widgetSmallPostOffsetKey)
        reloadWidgetTimelines()
    }
    
    private func migrateFromStandardDefaultsIfNeeded() {
        let sharedExists = defaults.data(forKey: AppGroupConfig.userSettingsKey) != nil
        guard !sharedExists else { return }
        
        if let legacy = UserDefaults.standard.data(forKey: AppGroupConfig.userSettingsKey) {
            defaults.set(legacy, forKey: AppGroupConfig.userSettingsKey)
        }
    }
    
    private func cachedPostsKey(for platform: BlogPlatform) -> String {
        switch platform {
        case .tistory:
            AppGroupConfig.widgetCachedPostsTistoryKey
        case .velog:
            AppGroupConfig.widgetCachedPostsVelogKey
        }
    }
    
    private func cachedUpdatedAtKey(for platform: BlogPlatform) -> String {
        switch platform {
        case .tistory:
            AppGroupConfig.widgetCachedUpdatedAtTistoryKey
        case .velog:
            AppGroupConfig.widgetCachedUpdatedAtVelogKey
        }
    }
    
    private func reloadWidgetTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupConfig.widgetKind)
        #endif
    }
}

private struct WidgetCachedPost: Codable {
    let id: String
    let title: String
    let url: String
    let publishedDate: Date?
    let summary: String?
}
