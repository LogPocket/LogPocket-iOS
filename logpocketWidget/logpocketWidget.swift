//
//  logpocketWidget.swift
//  logpocketWidget
//

import SwiftUI
import WidgetKit
import Foundation
import AppIntents

private enum WidgetGroupConfig {
    static let suiteName = "group.com.markrudy.logpocket1"
    static let widgetKind = "logpocketWidget"
    static let userSettingsKey = "userSettings"
    static let largePostOffsetKey = "widgetLargePostOffset"
    static let smallPostOffsetKey = "widgetSmallPostOffset"
    static let cachedPostsTistoryKey = "widgetCachedPostsTistory"
    static let cachedPostsVelogKey = "widgetCachedPostsVelog"
    static let cachedUpdatedAtTistoryKey = "widgetCachedUpdatedAtTistory"
    static let cachedUpdatedAtVelogKey = "widgetCachedUpdatedAtVelog"
    static let maxPosts = 40
}

enum WidgetPlatform: String, Codable {
    case tistory = "Tistory"
    case velog = "Velog"
    
    var symbolName: String {
        switch self {
        case .tistory:
            return "t.square.fill"
        case .velog:
            return "v.square.fill"
        }
    }
    
    var tint: Color {
        switch self {
        case .tistory:
            return .orange
        case .velog:
            return .green
        }
    }
}

private struct WidgetUserSettings: Codable {
    var tistoryURL: String?
    var velogURL: String?
    var hasCompletedOnboarding: Bool = false
    var preferredPlatform: WidgetPlatform?
    
    var hasTistory: Bool { !(tistoryURL ?? "").isEmpty }
    var hasVelog: Bool { !(velogURL ?? "").isEmpty }
}

private struct WidgetUserSettingsPayload: Decodable {
    let tistoryURL: String?
    let velogURL: String?
    let hasCompletedOnboarding: Bool?
    let preferredPlatform: String?
}

private struct WidgetCachedPost: Codable {
    let id: String
    let title: String
    let url: String
    let publishedDate: Date?
    let summary: String?
}

struct WidgetPost: Identifiable {
    let id: String
    let title: String
    let url: String
    let platform: WidgetPlatform
    let publishedDate: Date?
    let summary: String?
}

struct WidgetFeedResult {
    let posts: [WidgetPost]
    let platform: WidgetPlatform?
    let lastUpdatedAt: Date?
    let errorMessage: String?
    let isFromCache: Bool
}

struct LogPocketEntry: TimelineEntry {
    let date: Date
    let posts: [WidgetPost]
    let errorMessage: String?
    let largePostOffset: Int
    let smallPostOffset: Int
    let platform: WidgetPlatform?
    let lastUpdatedAt: Date?
    let isFromCache: Bool
}

struct LogPocketProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogPocketEntry {
        LogPocketEntry(
            date: .now,
            posts: samplePosts,
            errorMessage: nil,
            largePostOffset: 0,
            smallPostOffset: 0,
            platform: .velog,
            lastUpdatedAt: .now,
            isFromCache: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LogPocketEntry) -> Void) {
        Task {
            let result = await WidgetFeedLoader.loadFeed()
            let posts = context.isPreview && result.posts.isEmpty ? samplePosts : result.posts
            let offset = WidgetFeedLoader.loadLargePostOffset()
            let smallOffset = WidgetFeedLoader.loadSmallPostOffset()
            
            completion(
                LogPocketEntry(
                    date: .now,
                    posts: posts,
                    errorMessage: result.errorMessage,
                    largePostOffset: offset,
                    smallPostOffset: smallOffset,
                    platform: result.platform,
                    lastUpdatedAt: result.lastUpdatedAt,
                    isFromCache: result.isFromCache
                )
            )
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LogPocketEntry>) -> Void) {
        Task {
            let result = await WidgetFeedLoader.loadFeed()
            let offset = WidgetFeedLoader.loadLargePostOffset()
            let smallOffset = WidgetFeedLoader.loadSmallPostOffset()
            
            let entry = LogPocketEntry(
                date: .now,
                posts: result.posts,
                errorMessage: result.errorMessage,
                largePostOffset: offset,
                smallPostOffset: smallOffset,
                platform: result.platform,
                lastUpdatedAt: result.lastUpdatedAt,
                isFromCache: result.isFromCache
            )
            
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 10, to: .now) ?? .now.addingTimeInterval(600)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
    
    private var samplePosts: [WidgetPost] {
        [
            WidgetPost(
                id: "sample-1",
                title: "백준 1234번 - DP 풀이 정리",
                url: "https://example.com",
                platform: .velog,
                publishedDate: Date(),
                summary: "동적 계획법으로 문제를 해결한 과정을 정리했습니다."
            ),
            WidgetPost(
                id: "sample-2",
                title: "SwiftUI 상태 관리 정리",
                url: "https://example.com",
                platform: .velog,
                publishedDate: Date().addingTimeInterval(-86400),
                summary: "State, Observable, Environment 흐름 요약."
            ),
            WidgetPost(
                id: "sample-3",
                title: "제주도 여행 3일차 기록",
                url: "https://example.com",
                platform: .tistory,
                publishedDate: Date().addingTimeInterval(-172800),
                summary: "비 오는 날 우도에서 본 풍경과 식당 기록."
            )
        ]
    }
}

struct logpocketWidgetEntryView: View {
    var entry: LogPocketProvider.Entry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            largeWidget
        }
    }
    
    private var accentColor: Color {
        entry.platform?.tint ?? .accentColor
    }
    
    private var platformLabel: String {
        entry.platform?.rawValue ?? "Blog"
    }
    
    private var smallIndex: Int {
        guard !entry.posts.isEmpty else { return 0 }
        let count = entry.posts.count
        return ((entry.smallPostOffset % count) + count) % count
    }
    
    private var selectedSmallPost: WidgetPost? {
        guard !entry.posts.isEmpty else { return nil }
        return entry.posts[smallIndex]
    }
    
    private var largeIndex: Int {
        guard !entry.posts.isEmpty else { return 0 }
        let count = entry.posts.count
        return ((entry.largePostOffset % count) + count) % count
    }
    
    private var largeVisiblePosts: [WidgetPost] {
        circularPosts(from: entry.posts, start: largeIndex, limit: 7)
    }
    
    private var largePrimaryPost: WidgetPost? {
        largeVisiblePosts.first
    }
    
    private var largeSecondaryPosts: [WidgetPost] {
        Array(largeVisiblePosts.dropFirst())
    }
    
    private var syncStatusText: String {
        if let lastUpdatedAt = entry.lastUpdatedAt {
            let relative = Self.relativeFormatter.localizedString(for: lastUpdatedAt, relativeTo: entry.date)
            return entry.isFromCache ? "캐시 · \(relative)" : "업데이트 \(relative)"
        }
        return entry.isFromCache ? "캐시 데이터" : "업데이트 대기"
    }
    
    private var smallWidget: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let post = selectedSmallPost {
                    VStack(alignment: .leading, spacing: 8) {
                        headerBadge(label: platformLabel, detail: "\(smallIndex + 1)/\(entry.posts.count)")
                        
                        Text(post.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        if let summary = post.summary, !summary.isEmpty {
                            Text(summary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer(minLength: 0)
                        
                        HStack(spacing: 6) {
                            dateText(post.publishedDate)
                                .font(.caption2)
                            if entry.isFromCache {
                                Text("캐시")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                } else {
                    emptyState
                        .padding(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(selectedSmallPost.flatMap { URL(string: $0.url) })
    }
    
    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 7) {
            headerBadge(label: "\(platformLabel) 최근 글", detail: syncStatusText, showsRefreshButton: true)
            
            if entry.posts.isEmpty {
                emptyState
            } else {
                ForEach(Array(entry.posts.prefix(5).enumerated()), id: \.element.id) { index, post in
                    mediumPostRow(post: post, rank: index + 1)
                }
                
                if entry.posts.count > 5 {
                    Text("+\(entry.posts.count - 5)개 더")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerBadge(
                label: "\(platformLabel) 전체 글",
                detail: "\(entry.posts.count)개 · \(syncStatusText)",
                showsRefreshButton: true
            )
            
            if let primary = largePrimaryPost {
                largeFeaturedPost(primary)
                
                ForEach(Array(largeSecondaryPosts.enumerated()), id: \.element.id) { index, post in
                    largePostRow(post: post, rank: index + 2)
                }
                
                Spacer(minLength: 2)
                
                HStack(spacing: 8) {
                    Button(intent: ChangeLargePostIntent(direction: .previous)) {
                        navigationButtonLabel(title: "이전", symbol: "chevron.left", isLeading: true)
                    }
                    .buttonStyle(.plain)
                    
                    Button(intent: ChangeLargePostIntent(direction: .next)) {
                        navigationButtonLabel(title: "다음", symbol: "chevron.right", isLeading: false)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                emptyState
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    @ViewBuilder
    private func mediumPostRow(post: WidgetPost, rank: Int) -> some View {
        if let url = URL(string: post.url) {
            Link(destination: url) {
                mediumPostRowContent(post: post, rank: rank)
            }
        } else {
            mediumPostRowContent(post: post, rank: rank)
        }
    }
    
    private func mediumPostRowContent(post: WidgetPost, rank: Int) -> some View {
        HStack(spacing: 7) {
            Text("\(rank)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
                .frame(width: 12, alignment: .leading)
            
            Text(post.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            dateText(post.publishedDate)
                .font(.caption2)
        }
    }
    
    @ViewBuilder
    private func largeFeaturedPost(_ post: WidgetPost) -> some View {
        if let url = URL(string: post.url) {
            Link(destination: url) {
                largeFeaturedCard(post)
            }
        } else {
            largeFeaturedCard(post)
        }
    }
    
    private func largeFeaturedCard(_ post: WidgetPost) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.title)
                .font(.headline)
                .lineLimit(2)
            
            if let summary = post.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            dateText(post.publishedDate)
                .font(.caption2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    @ViewBuilder
    private func largePostRow(post: WidgetPost, rank: Int) -> some View {
        if let url = URL(string: post.url) {
            Link(destination: url) {
                largePostRowContent(post: post, rank: rank)
            }
        } else {
            largePostRowContent(post: post, rank: rank)
        }
    }
    
    private func largePostRowContent(post: WidgetPost, rank: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(rank)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
                .frame(width: 12, alignment: .leading)
            
            Text(post.title)
                .font(.caption)
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            dateText(post.publishedDate)
                .font(.caption2)
        }
    }
    
    private func navigationButtonLabel(title: String, symbol: String, isLeading: Bool) -> some View {
        HStack(spacing: 5) {
            if isLeading { Image(systemName: symbol) }
            Text(title)
                .font(.caption.weight(.semibold))
            if !isLeading { Image(systemName: symbol) }
        }
        .foregroundStyle(.white.opacity(0.95))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.95), accentColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
    
    private func headerBadge(label: String, detail: String, showsRefreshButton: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: entry.platform?.symbolName ?? "doc.text.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            if showsRefreshButton {
                Button(intent: RefreshWidgetTimelineIntent()) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func dateText(_ date: Date?) -> Text {
        guard let date else { return Text("-") }
        return Text(date, style: .date)
            .foregroundStyle(.secondary)
    }
    
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LogPocket", systemImage: "book.pages")
                .font(.headline)
                .foregroundStyle(accentColor)
            Text(entry.errorMessage ?? "앱에서 블로그를 연결한 뒤 홈 화면을 새로고침해 주세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Spacer(minLength: 0)
        }
    }
    
    private func circularPosts(from posts: [WidgetPost], start: Int, limit: Int) -> [WidgetPost] {
        guard !posts.isEmpty else { return [] }
        let count = min(limit, posts.count)
        return (0..<count).map { offset in
            let index = (start + offset) % posts.count
            return posts[index]
        }
    }
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

struct logpocketWidget: Widget {
    let kind: String = WidgetGroupConfig.widgetKind
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogPocketProvider()) { entry in
            logpocketWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("LogPocket")
        .description("앱의 최신 블로그 글을 빠르게 확인하고 바로 열어보세요.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

enum WidgetFeedLoader {
    static func loadFeed() async -> WidgetFeedResult {
        let hasSharedDefaults = sharedDefaults() != nil
        let settings = loadSettings()
        let resolvedPlatform = settings.flatMap { resolvePlatform(from: $0) }
        let cached = loadCachedSnapshot(preferred: resolvedPlatform)
        
        guard let settings else {
            if cached.posts.isEmpty {
                return WidgetFeedResult(
                    posts: [],
                    platform: nil,
                    lastUpdatedAt: nil,
                    errorMessage: hasSharedDefaults
                        ? "앱에서 블로그 링크를 먼저 등록해 주세요."
                        : "앱/위젯 App Groups 권한을 활성화해 주세요.",
                    isFromCache: false
                )
            }
            
            return WidgetFeedResult(
                posts: cached.posts,
                platform: cached.platform,
                lastUpdatedAt: cached.updatedAt,
                errorMessage: "설정 정보를 찾지 못해 마지막 동기화 글을 표시해요.",
                isFromCache: true
            )
        }
        
        guard let platform = resolvedPlatform else {
            if cached.posts.isEmpty {
                return WidgetFeedResult(
                    posts: [],
                    platform: nil,
                    lastUpdatedAt: nil,
                    errorMessage: "표시할 블로그 플랫폼이 없습니다.",
                    isFromCache: false
                )
            }
            
            return WidgetFeedResult(
                posts: cached.posts,
                platform: cached.platform,
                lastUpdatedAt: cached.updatedAt,
                errorMessage: "마지막 동기화 글을 표시 중이에요.",
                isFromCache: true
            )
        }
        
        guard let feedURL = buildFeedURL(from: settings, platform: platform) else {
            if cached.posts.isEmpty {
                return WidgetFeedResult(
                    posts: [],
                    platform: platform,
                    lastUpdatedAt: nil,
                    errorMessage: "블로그 링크 형식을 확인해 주세요.",
                    isFromCache: false
                )
            }
            
            return WidgetFeedResult(
                posts: cached.posts,
                platform: cached.platform ?? platform,
                lastUpdatedAt: cached.updatedAt,
                errorMessage: "마지막 동기화 글을 표시 중이에요.",
                isFromCache: true
            )
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let items = WidgetRSSParser.parse(data)
            let fetchedPosts = makePosts(from: items, platform: platform)
            
            if fetchedPosts.isEmpty {
                if cached.posts.isEmpty {
                    return WidgetFeedResult(
                        posts: [],
                        platform: platform,
                        lastUpdatedAt: nil,
                        errorMessage: "새 글을 찾지 못했어요.",
                        isFromCache: false
                    )
                }
                
                return WidgetFeedResult(
                    posts: cached.posts,
                    platform: cached.platform ?? platform,
                    lastUpdatedAt: cached.updatedAt,
                    errorMessage: "새 글을 가져오지 못해 캐시를 보여줘요.",
                    isFromCache: true
                )
            }
            
            let mergedPosts = mergePosts(primary: fetchedPosts, secondary: cached.posts)
            saveCachedPosts(mergedPosts, for: platform)
            
            return WidgetFeedResult(
                posts: mergedPosts,
                platform: platform,
                lastUpdatedAt: .now,
                errorMessage: nil,
                isFromCache: false
            )
        } catch {
            if cached.posts.isEmpty {
                return WidgetFeedResult(
                    posts: [],
                    platform: platform,
                    lastUpdatedAt: nil,
                    errorMessage: "네트워크 오류로 글을 불러오지 못했어요.",
                    isFromCache: false
                )
            }
            
            return WidgetFeedResult(
                posts: cached.posts,
                platform: cached.platform ?? platform,
                lastUpdatedAt: cached.updatedAt,
                errorMessage: "오프라인 상태라 캐시 글을 표시해요.",
                isFromCache: true
            )
        }
    }
    
    private static func loadSettings() -> WidgetUserSettings? {
        guard let defaults = sharedDefaults() else {
            return nil
        }
        
        guard let data = defaults.data(forKey: WidgetGroupConfig.userSettingsKey) else {
            return nil
        }
        
        if let settings = try? JSONDecoder().decode(WidgetUserSettings.self, from: data) {
            return settings
        }
        
        guard let payload = try? JSONDecoder().decode(WidgetUserSettingsPayload.self, from: data) else {
            return nil
        }
        
        return WidgetUserSettings(
            tistoryURL: payload.tistoryURL,
            velogURL: payload.velogURL,
            hasCompletedOnboarding: payload.hasCompletedOnboarding ?? false,
            preferredPlatform: platform(from: payload.preferredPlatform)
        )
    }
    
    private static func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: WidgetGroupConfig.suiteName)
    }
    
    private static func resolvePlatform(from settings: WidgetUserSettings) -> WidgetPlatform? {
        if let preferred = settings.preferredPlatform,
           buildFeedURL(from: settings, platform: preferred) != nil {
            return preferred
        }
        
        if buildFeedURL(from: settings, platform: .tistory) != nil {
            return .tistory
        }
        
        if buildFeedURL(from: settings, platform: .velog) != nil {
            return .velog
        }
        
        return nil
    }
    
    private static func platform(from rawValue: String?) -> WidgetPlatform? {
        guard let normalized = rawValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !normalized.isEmpty else {
            return nil
        }
        
        switch normalized {
        case "tistory":
            return .tistory
        case "velog":
            return .velog
        default:
            return nil
        }
    }
    
    static func loadLargePostOffset() -> Int {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        return defaults.integer(forKey: WidgetGroupConfig.largePostOffsetKey)
    }
    
    static func adjustLargePostOffset(by delta: Int) {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        let current = defaults.integer(forKey: WidgetGroupConfig.largePostOffsetKey)
        defaults.set(current + delta, forKey: WidgetGroupConfig.largePostOffsetKey)
    }
    
    static func loadSmallPostOffset() -> Int {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        return defaults.integer(forKey: WidgetGroupConfig.smallPostOffsetKey)
    }
    
    static func adjustSmallPostOffset(by delta: Int) {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        let current = defaults.integer(forKey: WidgetGroupConfig.smallPostOffsetKey)
        defaults.set(current + delta, forKey: WidgetGroupConfig.smallPostOffsetKey)
    }
    
    private static func makePosts(from items: [WidgetRSSItem], platform: WidgetPlatform) -> [WidgetPost] {
        let posts = items.compactMap { item -> WidgetPost? in
            guard let title = item.title, let link = item.link else { return nil }
            return WidgetPost(
                id: link,
                title: title,
                url: link,
                platform: platform,
                publishedDate: item.publishedDate,
                summary: item.summary
            )
        }
        
        return posts.sorted { left, right in
            (left.publishedDate ?? .distantPast) > (right.publishedDate ?? .distantPast)
        }
    }
    
    private static func mergePosts(primary: [WidgetPost], secondary: [WidgetPost]) -> [WidgetPost] {
        var seen = Set<String>()
        let merged = (primary + secondary).filter { post in
            seen.insert(post.id).inserted
        }
        
        let sorted = merged.sorted { left, right in
            (left.publishedDate ?? .distantPast) > (right.publishedDate ?? .distantPast)
        }
        
        return Array(sorted.prefix(WidgetGroupConfig.maxPosts))
    }
    
    private static func saveCachedPosts(_ posts: [WidgetPost], for platform: WidgetPlatform) {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        let cache = posts.map { post in
            WidgetCachedPost(
                id: post.id,
                title: post.title,
                url: post.url,
                publishedDate: post.publishedDate,
                summary: post.summary
            )
        }
        
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: cachedPostsKey(for: platform))
        defaults.set(Date(), forKey: cachedUpdatedAtKey(for: platform))
    }
    
    private static func buildFeedURL(from settings: WidgetUserSettings, platform: WidgetPlatform) -> URL? {
        switch platform {
        case .tistory:
            guard let id = tistoryID(from: settings.tistoryURL ?? ""), !id.isEmpty else { return nil }
            return URL(string: "https://\(id).tistory.com/rss")
        case .velog:
            guard let id = velogID(from: settings.velogURL ?? ""), !id.isEmpty else { return nil }
            return URL(string: "https://v2.velog.io/rss/\(id)")
        }
    }
    
    private static func tistoryID(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let host = host(from: trimmed),
           let range = host.range(of: ".tistory.com", options: [.caseInsensitive]) {
            return normalizedIdentifier(String(host[..<range.lowerBound]))
        }
        
        if let range = trimmed.range(of: ".tistory.com", options: [.caseInsensitive]) {
            let prefix = trimmed[..<range.lowerBound]
            let token = prefix.split(separator: "/").last.map(String.init) ?? String(prefix)
            return normalizedIdentifier(token)
        }
        
        return normalizedIdentifier(trimmed)
    }
    
    private static func velogID(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if let host = host(from: trimmed),
           host.lowercased().contains("velog.io"),
           let pathID = firstPathComponent(from: trimmed) {
            return normalizedIdentifier(pathID.replacingOccurrences(of: "@", with: ""))
        }
        
        if let atRange = trimmed.range(of: "@") {
            let suffix = trimmed[atRange.upperBound...]
            return normalizedIdentifier(firstToken(in: String(suffix)))
        }
        
        if let range = trimmed.range(of: "velog.io/", options: [.caseInsensitive]) {
            let suffix = trimmed[range.upperBound...]
            return normalizedIdentifier(firstToken(in: String(suffix)))
        }
        
        return normalizedIdentifier(trimmed.replacingOccurrences(of: "@", with: ""))
    }
    
    private static func host(from raw: String) -> String? {
        if let host = URL(string: raw)?.host {
            return host
        }
        
        return URL(string: "https://\(raw)")?.host
    }
    
    private static func firstPathComponent(from raw: String) -> String? {
        let normalized = raw.hasPrefix("http://") || raw.hasPrefix("https://")
            ? raw
            : "https://\(raw)"
        guard let components = URLComponents(string: normalized) else { return nil }
        return components.path.split(separator: "/").first.map(String.init)
    }
    
    private static func firstToken(in raw: String) -> String {
        raw
            .split(whereSeparator: { "/?#".contains($0) })
            .first
            .map(String.init) ?? raw
    }
    
    private static func normalizedIdentifier(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(raw.unicodeScalars.filter { allowed.contains($0) })
    }
    
    private struct CachedSnapshot {
        let posts: [WidgetPost]
        let platform: WidgetPlatform?
        let updatedAt: Date?
    }
    
    private static func loadCachedSnapshot(preferred: WidgetPlatform?) -> CachedSnapshot {
        let tistory = loadCachedSnapshot(for: .tistory)
        let velog = loadCachedSnapshot(for: .velog)
        
        guard let preferred else {
            let merged = mergePosts(primary: tistory.posts, secondary: velog.posts)
            let updatedAt = newestDate(tistory.updatedAt, velog.updatedAt)
            let dominantPlatform: WidgetPlatform? = tistory.posts.count >= velog.posts.count ? .tistory : .velog
            return CachedSnapshot(
                posts: merged,
                platform: merged.isEmpty ? nil : dominantPlatform,
                updatedAt: updatedAt
            )
        }
        
        let preferredSnapshot = preferred == .tistory ? tistory : velog
        if !preferredSnapshot.posts.isEmpty {
            return preferredSnapshot
        }
        
        let fallbackSnapshot = preferred == .tistory ? velog : tistory
        if !fallbackSnapshot.posts.isEmpty {
            return fallbackSnapshot
        }
        
        return CachedSnapshot(posts: [], platform: preferred, updatedAt: nil)
    }
    
    private static func loadCachedSnapshot(for platform: WidgetPlatform) -> CachedSnapshot {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        guard let data = defaults.data(forKey: cachedPostsKey(for: platform)),
              let cacheItems = try? JSONDecoder().decode([WidgetCachedPost].self, from: data) else {
            return CachedSnapshot(posts: [], platform: platform, updatedAt: nil)
        }
        
        let posts = cacheItems.map { item in
            WidgetPost(
                id: item.id,
                title: item.title,
                url: item.url,
                platform: platform,
                publishedDate: item.publishedDate,
                summary: item.summary
            )
        }
        
        let updatedAt = defaults.object(forKey: cachedUpdatedAtKey(for: platform)) as? Date
        
        return CachedSnapshot(
            posts: posts,
            platform: platform,
            updatedAt: updatedAt
        )
    }
    
    private static func cachedPostsKey(for platform: WidgetPlatform) -> String {
        switch platform {
        case .tistory:
            WidgetGroupConfig.cachedPostsTistoryKey
        case .velog:
            WidgetGroupConfig.cachedPostsVelogKey
        }
    }
    
    private static func cachedUpdatedAtKey(for platform: WidgetPlatform) -> String {
        switch platform {
        case .tistory:
            WidgetGroupConfig.cachedUpdatedAtTistoryKey
        case .velog:
            WidgetGroupConfig.cachedUpdatedAtVelogKey
        }
    }
    
    private static func newestDate(_ left: Date?, _ right: Date?) -> Date? {
        switch (left, right) {
        case let (l?, r?):
            max(l, r)
        case let (l?, nil):
            l
        case let (nil, r?):
            r
        default:
            nil
        }
    }
}

enum LargePostDirection: String, AppEnum {
    case previous
    case next
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Post Direction")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .previous: "Previous",
        .next: "Next"
    ]
    
    var delta: Int {
        switch self {
        case .previous: return -1
        case .next: return 1
        }
    }
}

struct RefreshWidgetTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget Data"
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGroupConfig.widgetKind)
        return .result()
    }
}

struct ChangeLargePostIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Large Widget Post"
    
    @Parameter(title: "Direction")
    var direction: LargePostDirection
    
    init() {
        direction = .next
    }
    
    init(direction: LargePostDirection) {
        self.direction = direction
    }
    
    func perform() async throws -> some IntentResult {
        WidgetFeedLoader.adjustLargePostOffset(by: direction.delta)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGroupConfig.widgetKind)
        return .result()
    }
}

private struct WidgetRSSItem {
    let title: String?
    let link: String?
    let summary: String?
    let publishedDate: Date?
}

private final class WidgetRSSParser: NSObject, XMLParserDelegate {
    private var items: [WidgetRSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentSummary = ""
    private var currentAtomLink = ""
    private var isInsideItem = false
    
    static func parse(_ data: Data) -> [WidgetRSSItem] {
        let parser = WidgetRSSParser()
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
        attributes attributeDict: [String : String] = [:]
    ) {
        currentElement = elementName
        
        if elementName == "item" || elementName == "entry" {
            isInsideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            currentSummary = ""
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
        case "description", "summary", "content":
            currentSummary += string
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
            let summary = cleanedSummary(from: currentSummary)
            let pubDate = parseDate(currentPubDate)
            
            if !title.isEmpty, !link.isEmpty {
                items.append(
                    WidgetRSSItem(
                        title: title,
                        link: link,
                        summary: summary,
                        publishedDate: pubDate
                    )
                )
            }
            
            isInsideItem = false
        }
        
        currentElement = ""
    }
    
    private func stripHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    private func cleanedSummary(from raw: String) -> String {
        stripHTML(raw)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseDate(_ string: String) -> Date? {
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
