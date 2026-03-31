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
        let platform = selectedPlatform
        
        Task { [weak self] in
            guard let self else { return }
            let posts = await self.fetchBlogPosts(for: platform)
            
            await MainActor.run {
                self.blogPosts = posts
                self.isLoading = false
            }
        }
    }
    
    private func fetchBlogPosts(for platform: BlogPlatform) async -> [BlogPost] {
        guard let feedURL = feedURL(for: platform) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let items = RSSParser.parse(data)
            
            return items.compactMap { item in
                guard let link = item.link, let title = item.title else { return nil }
                
                return BlogPost(
                    id: link,
                    title: title,
                    url: link,
                    platform: platform,
                    publishedDate: item.publishedDate
                )
            }
        } catch {
            return []
        }
    }
    
    private func feedURL(for platform: BlogPlatform) -> URL? {
        let sourceURL: String
        
        switch platform {
        case .tistory:
            sourceURL = settings.tistoryURL ?? ""
            guard !sourceURL.isEmpty else { return nil }
            let trimmed = sourceURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return URL(string: "\(trimmed)/rss")
        case .velog:
            sourceURL = settings.velogURL ?? ""
            guard let id = velogUserID(from: sourceURL), !id.isEmpty else { return nil }
            return URL(string: "https://v2.velog.io/rss/\(id)")
        }
    }
    
    private func velogUserID(from urlString: String) -> String? {
        guard let atRange = urlString.range(of: "@") else { return nil }
        let suffix = urlString[atRange.upperBound...]
        let id = suffix.split(separator: "/").first.map(String.init)
        return id?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct RSSItem {
    let title: String?
    let link: String?
    let publishedDate: Date?
}

private final class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentAtomLink = ""
    private var isInsideItem = false
    
    static func parse(_ data: Data) -> [RSSItem] {
        let parser = RSSParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.items
    }
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        
        if elementName == "item" || elementName == "entry" {
            isInsideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            currentAtomLink = ""
        }
        
        if isInsideItem, elementName == "link", let href = attributeDict["href"] {
            currentAtomLink = href
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "pubDate", "published", "updated":
            currentPubDate += string
        default:
            break
        }
    }
    
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "item" || elementName == "entry" {
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let linkCandidate = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let atomLink = currentAtomLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let link = linkCandidate.isEmpty ? atomLink : linkCandidate
            let pubDate = date(from: currentPubDate)
            
            if !title.isEmpty, !link.isEmpty {
                items.append(
                    RSSItem(
                        title: title,
                        link: link,
                        publishedDate: pubDate
                    )
                )
            }
            
            isInsideItem = false
        }
        
        currentElement = ""
    }
    
    private func date(from string: String) -> Date? {
        let raw = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formats = [
            "E, d MMM yyyy HH:mm:ss Z",
            "E, dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        
        return nil
    }
}
