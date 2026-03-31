//
//  HomeViewModel.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var selectedPlatform: BlogPlatform
    @Published var blogPosts: [BlogPost] = []
    @Published var isLoading: Bool = false
    @Published var showLinkRequiredAlert: Bool = false
    @Published var shouldNavigateToOnboarding: Bool = false
    
    private var settings: UserSettings
    
    init() {
        settings = UserDefaultsManager.shared.loadSettings()
        selectedPlatform = settings.preferredPlatform ?? .tistory
        loadBlogPosts()
    }
    
    func refreshSettings() {
        settings = UserDefaultsManager.shared.loadSettings()
        selectedPlatform = settings.preferredPlatform ?? (settings.hasTistory ? .tistory : .velog)
        loadBlogPosts()
    }
    
    var currentBlogIdentifier: String {
        let sourceURL: String
        switch selectedPlatform {
        case .tistory:
            sourceURL = settings.tistoryURL ?? ""
            let host = URL(string: sourceURL)?.host ?? sourceURL
            return host.replacingOccurrences(of: ".tistory.com", with: "")
        case .velog:
            sourceURL = settings.velogURL ?? ""
            if let range = sourceURL.range(of: "@") {
                return String(sourceURL[range.upperBound...]).replacingOccurrences(of: "/posts", with: "")
            }
            return sourceURL
        }
    }
    
    func selectPlatform(_ platform: BlogPlatform) {
        let hasLink = platform == .tistory ? settings.hasTistory : settings.hasVelog
        
        if !hasLink {
            showLinkRequiredAlert = true
            return
        }
        
        selectedPlatform = platform
        var updatedSettings = settings
        updatedSettings.preferredPlatform = platform
        UserDefaultsManager.shared.saveSettings(updatedSettings)
        settings = updatedSettings
        loadBlogPosts()
    }
    
    func navigateToOnboarding() {
        shouldNavigateToOnboarding = true
    }
    
    private func loadBlogPosts() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.blogPosts = self.generateSamplePosts()
            self.isLoading = false
        }
    }
    
    private func generateSamplePosts() -> [BlogPost] {
        let baseURL: String
        
        switch selectedPlatform {
        case .tistory:
            baseURL = settings.tistoryURL ?? ""
        case .velog:
            baseURL = settings.velogURL ?? ""
        }
        
        guard !baseURL.isEmpty else { return [] }
        
        return (1...10).map { index in
            BlogPost(
                id: UUID().uuidString,
                title: "\(selectedPlatform.rawValue) 블로그 포스트 \(index)",
                url: baseURL,
                platform: selectedPlatform,
                publishedDate: Date().addingTimeInterval(-Double(index) * 86400)
            )
        }
    }
}
