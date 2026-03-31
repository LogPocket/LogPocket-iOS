//
//  OnboardingViewModel.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import Foundation
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var tistoryID: String = ""
    @Published var velogID: String = ""
    @Published var isCompleteButtonEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadExistingSettings()
        setupValidation()
    }
    
    private func loadExistingSettings() {
        let settings = UserDefaultsManager.shared.loadSettings()
        tistoryID = extractID(from: settings.tistoryURL ?? "", for: .tistory)
        velogID = extractID(from: settings.velogURL ?? "", for: .velog)
    }
    
    private func setupValidation() {
        Publishers.CombineLatest($tistoryID, $velogID)
            .map { tistory, velog in
                let hasTistory = !self.sanitizeID(tistory, for: .tistory).isEmpty
                let hasVelog = !self.sanitizeID(velog, for: .velog).isEmpty
                return hasTistory || hasVelog
            }
            .assign(to: &$isCompleteButtonEnabled)
    }
    
    func sanitizeID(_ raw: String, for platform: BlogPlatform) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch platform {
        case .tistory:
            return trimmed
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: ".tistory.com", with: "")
                .replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: "@", with: "")
        case .velog:
            return trimmed
                .replacingOccurrences(of: "https://velog.io/@", with: "")
                .replacingOccurrences(of: "http://velog.io/@", with: "")
                .replacingOccurrences(of: "velog.io/@", with: "")
                .replacingOccurrences(of: "/posts", with: "")
                .replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: "@", with: "")
        }
    }
    
    private func extractID(from storedURL: String, for platform: BlogPlatform) -> String {
        sanitizeID(storedURL, for: platform)
    }
    
    func normalizedURLFromID(_ id: String, for platform: BlogPlatform) -> String? {
        let cleanedID = sanitizeID(id, for: platform)
        guard !cleanedID.isEmpty else { return nil }
        
        switch platform {
        case .tistory:
            return "https://\(cleanedID).tistory.com/"
        case .velog:
            return "https://velog.io/@\(cleanedID)/posts"
        }
    }
    
    func saveSettings(completion: @escaping () -> Void) {
        var settings = UserDefaultsManager.shared.loadSettings()
        
        if let normalizedTistory = normalizedURLFromID(tistoryID, for: .tistory) {
            settings.tistoryURL = normalizedTistory
        }
        
        if let normalizedVelog = normalizedURLFromID(velogID, for: .velog) {
            settings.velogURL = normalizedVelog
        }
        
        settings.hasCompletedOnboarding = true
        
        if settings.hasTistory {
            settings.preferredPlatform = .tistory
        } else if settings.hasVelog {
            settings.preferredPlatform = .velog
        }
        
        UserDefaultsManager.shared.saveSettings(settings)
        completion()
    }
}
