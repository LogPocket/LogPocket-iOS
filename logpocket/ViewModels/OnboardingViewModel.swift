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
            .map { [weak self] tistory, velog in
                guard let self else { return false }
                let hasTistory = !self.sanitizeID(tistory, for: .tistory).isEmpty
                let hasVelog = !self.sanitizeID(velog, for: .velog).isEmpty
                return hasTistory || hasVelog
            }
            .assign(to: &$isCompleteButtonEnabled)
    }
    
    func sanitizeID(_ raw: String, for platform: BlogPlatform) -> String {
        let extracted: String
        
        switch platform {
        case .tistory:
            extracted = extractTistoryID(from: raw)
        case .velog:
            extracted = extractVelogID(from: raw)
        }
        
        return normalizedIdentifier(extracted)
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
        let previousSettings = UserDefaultsManager.shared.loadSettings()
        var settings = previousSettings
        
        settings.tistoryURL = normalizedURLFromID(tistoryID, for: .tistory)
        settings.velogURL = normalizedURLFromID(velogID, for: .velog)
        
        settings.hasCompletedOnboarding = true
        settings.preferredPlatform = resolvedPreferredPlatform(
            from: previousSettings.preferredPlatform,
            hasTistory: settings.hasTistory,
            hasVelog: settings.hasVelog
        )
        
        if previousSettings.tistoryURL != settings.tistoryURL {
            UserDefaultsManager.shared.clearLatestPosts(for: .tistory, reloadWidget: false)
        }
        
        if previousSettings.velogURL != settings.velogURL {
            UserDefaultsManager.shared.clearLatestPosts(for: .velog, reloadWidget: false)
        }
        
        UserDefaultsManager.shared.saveSettings(settings)
        completion()
    }
    
    private func resolvedPreferredPlatform(
        from existing: BlogPlatform?,
        hasTistory: Bool,
        hasVelog: Bool
    ) -> BlogPlatform? {
        if hasTistory, !hasVelog {
            return .tistory
        }
        
        if hasVelog, !hasTistory {
            return .velog
        }
        
        if hasTistory, hasVelog {
            if let existing,
               (existing == .tistory && hasTistory) || (existing == .velog && hasVelog) {
                return existing
            }
            return .tistory
        }
        
        return nil
    }
    
    private func extractTistoryID(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if let host = host(from: trimmed),
           let range = host.range(of: ".tistory.com", options: [.caseInsensitive]) {
            return String(host[..<range.lowerBound])
        }
        
        if let range = trimmed.range(of: ".tistory.com", options: [.caseInsensitive]) {
            let prefix = trimmed[..<range.lowerBound]
            return prefix.split(separator: "/").last.map(String.init) ?? String(prefix)
        }
        
        return trimmed
    }
    
    private func extractVelogID(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if let host = host(from: trimmed),
           host.lowercased().contains("velog.io"),
           let pathID = firstPathComponent(from: trimmed) {
            return pathID.replacingOccurrences(of: "@", with: "")
        }
        
        if let atRange = trimmed.range(of: "@") {
            let suffix = trimmed[atRange.upperBound...]
            return firstToken(in: String(suffix))
        }
        
        if let range = trimmed.range(of: "velog.io/", options: [.caseInsensitive]) {
            let suffix = trimmed[range.upperBound...]
            return firstToken(in: String(suffix))
        }
        
        return trimmed.replacingOccurrences(of: "@", with: "")
    }
    
    private func host(from raw: String) -> String? {
        if let host = URL(string: raw)?.host {
            return host
        }
        
        return URL(string: "https://\(raw)")?.host
    }
    
    private func firstPathComponent(from raw: String) -> String? {
        let normalized = raw.hasPrefix("http://") || raw.hasPrefix("https://")
            ? raw
            : "https://\(raw)"
        guard let components = URLComponents(string: normalized) else { return nil }
        return components.path.split(separator: "/").first.map(String.init)
    }
    
    private func firstToken(in raw: String) -> String {
        raw
            .split(whereSeparator: { "/?#".contains($0) })
            .first
            .map(String.init) ?? raw
    }
    
    private func normalizedIdentifier(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(raw.unicodeScalars.filter { allowed.contains($0) })
    }
}
