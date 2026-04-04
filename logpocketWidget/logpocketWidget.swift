//
//  logpocketWidget.swift
//  logpocketWidget
//

import SwiftUI
import WidgetKit
import Foundation
import AppIntents

private enum WidgetGroupConfig {
    static let suiteName = "group.com.markrudy.logpockets"
    static let userSettingsKey = "userSettings"
    static let largePostOffsetKey = "widgetLargePostOffset"
    static let smallPostOffsetKey = "widgetSmallPostOffset"
}

private enum WidgetPlatform: String, Codable {
    case tistory = "Tistory"
    case velog = "Velog"
}

private struct WidgetUserSettings: Codable {
    var tistoryURL: String?
    var velogURL: String?
    var hasCompletedOnboarding: Bool = false
    var preferredPlatform: WidgetPlatform?
    
    var hasTistory: Bool { !(tistoryURL ?? "").isEmpty }
    var hasVelog: Bool { !(velogURL ?? "").isEmpty }
}

struct WidgetPost: Identifiable {
    let id: String
    let title: String
    let url: String
    let publishedDate: Date?
    let summary: String?
}

struct LogPocketEntry: TimelineEntry {
    let date: Date
    let posts: [WidgetPost]
    let errorMessage: String?
    let largePostOffset: Int
    let smallPostOffset: Int
}

struct LogPocketProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogPocketEntry {
        LogPocketEntry(date: .now, posts: samplePosts, errorMessage: nil, largePostOffset: 0, smallPostOffset: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LogPocketEntry) -> Void) {
        Task {
            let posts = await WidgetFeedLoader.loadPosts()
            let offset = WidgetFeedLoader.loadLargePostOffset()
            let smallOffset = WidgetFeedLoader.loadSmallPostOffset()
            completion(
                LogPocketEntry(
                    date: .now,
                    posts: posts.isEmpty ? samplePosts : posts,
                    errorMessage: posts.isEmpty ? "블로그 글을 불러오지 못했어요." : nil,
                    largePostOffset: offset,
                    smallPostOffset: smallOffset
                )
            )
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LogPocketEntry>) -> Void) {
        Task {
            let posts = await WidgetFeedLoader.loadPosts()
            let offset = WidgetFeedLoader.loadLargePostOffset()
            let smallOffset = WidgetFeedLoader.loadSmallPostOffset()
            let entry = LogPocketEntry(
                date: .now,
                posts: posts.isEmpty ? samplePosts : posts,
                errorMessage: posts.isEmpty ? "블로그 글을 불러오지 못했어요." : nil,
                largePostOffset: offset,
                smallPostOffset: smallOffset
            )
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
    
    private var samplePosts: [WidgetPost] {
        return LogPocketEntry(
            date: .now,
            posts: [
            WidgetPost(
                id: "sample-1",
                title: "백준 1234번 - DP 풀이 정리",
                url: "https://example.com",
                publishedDate: Date(),
                summary: "동적 계획법으로 문제를 해결한 과정을 정리했습니다."
            ),
            WidgetPost(
                id: "sample-2",
                title: "제주도 여행 3일차 기록",
                url: "https://example.com",
                publishedDate: Date().addingTimeInterval(-86400),
                summary: "비 오는 날 우도에서 본 풍경과 식당 기록."
            ),
            WidgetPost(
                id: "sample-3",
                title: "SwiftUI 상태 관리 정리",
                url: "https://example.com",
                publishedDate: Date().addingTimeInterval(-172800),
                summary: "State, Observable, Environment 흐름 요약."
            )
            ],
            errorMessage: nil,
            largePostOffset: 0,
            smallPostOffset: 0
        ).posts
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
    
    private var smallWidget: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let post = selectedSmallPost {
                    smallWidgetFilledContent(post: post)
                } else {
                    emptyState
                        .padding(.trailing, 14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(selectedSmallPost.flatMap { URL(string: $0.url) })
    }
    
    private var selectedSmallPost: WidgetPost? {
        guard !entry.posts.isEmpty else { return nil }
        let count = entry.posts.count
        let normalizedIndex = ((entry.smallPostOffset % count) + count) % count
        return entry.posts[normalizedIndex]
    }
    
    private func smallWidgetFilledContent(post: WidgetPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            smallWidgetHeaderRow
            
            Spacer(minLength: 4)
            
            Text(post.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(Self.smallWidgetDateFormatter.string(from: post.publishedDate ?? entry.date))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 6)
        .padding(.leading, 6)
        .padding(.trailing, 24)
        .padding(.bottom, 5)
    }
    
    private var smallWidgetHeaderRow: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(red: 46 / 255, green: 204 / 255, blue: 113 / 255))
                .frame(width: 18, height: 18)
                .overlay {
                    Text("V")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            Text("나의 기록")
                .font(.caption)
                .foregroundStyle(Color(white: 0.53))
        }
    }
    
    private static let smallWidgetDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy. MM. dd"
        return f
    }()
    
    private var mediumWidget: some View {
        ZStack {
            Color.clear
            if entry.posts.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    headerBadge(label: "최근 글")
                    ForEach(Array(entry.posts.prefix(3)).indices, id: \.self) { idx in
                        let post = entry.posts[idx]
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 7, height: 7)
                            Text(post.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            dateText(post.publishedDate)
                                .font(.caption2)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(entry.posts.first.flatMap { URL(string: $0.url) })
    }
    
    private var largeWidget: some View {
        ZStack {
            Color.clear
            if let selectedPost = selectedLargePost {
                VStack(alignment: .leading, spacing: 10) {
                    headerBadge(label: "추억 회선")
                    Text(selectedPost.title)
                        .font(.headline)
                        .lineLimit(3)
                    dateText(selectedPost.publishedDate)
                        .font(.caption)
                    if let summary = selectedPost.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(8)
                    }
                    
                    Spacer(minLength: 0)
                    
                    HStack(spacing: 10) {
                        Button(intent: ChangeLargePostIntent(direction: .previous)) {
                            navigationButtonLabel(title: "Previous", symbol: "chevron.left", isLeading: true)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: ChangeLargePostIntent(direction: .next)) {
                            navigationButtonLabel(title: "Next", symbol: "chevron.right", isLeading: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(selectedLargePost.flatMap { URL(string: $0.url) })
    }
    
    private var selectedLargePost: WidgetPost? {
        guard !entry.posts.isEmpty else { return nil }
        let count = entry.posts.count
        let normalizedIndex = ((entry.largePostOffset % count) + count) % count
        return entry.posts[normalizedIndex]
    }
    
    private func navigationButtonLabel(title: String, symbol: String, isLeading: Bool) -> some View {
        HStack(spacing: 6) {
            if isLeading {
                Image(systemName: symbol)
            }
            Text(title)
                .font(.caption.weight(.semibold))
            if !isLeading {
                Image(systemName: symbol)
            }
        }
        .foregroundStyle(.white.opacity(0.92))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.78), Color.gray.opacity(0.58)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
    
    private func headerBadge(label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.green.opacity(0.2))
                .frame(width: 18, height: 18)
                .overlay {
                    Text("V")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func dateText(_ date: Date?) -> Text {
        guard let date else { return Text("") }
        return Text(date, style: .date)
            .foregroundStyle(.secondary)
    }
    
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LogPocket")
                .font(.headline)
            Text(entry.errorMessage ?? "온보딩에서 블로그 아이디를 먼저 입력해 주세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(8)
    }
}

struct logpocketWidget: Widget {
    let kind: String = "logpocketWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogPocketProvider()) { entry in
            logpocketWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("LogPocket")
        .description("블로그 최신 글을 홈 화면에서 바로 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

enum WidgetFeedLoader {
    static func loadPosts() async -> [WidgetPost] {
        guard let settings = loadSettings() else { return [] }
        guard let feedURL = buildFeedURL(from: settings) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let items = WidgetRSSParser.parse(data)
            
            return items.compactMap { item in
                guard let title = item.title, let link = item.link else { return nil }
                return WidgetPost(
                    id: link,
                    title: title,
                    url: link,
                    publishedDate: item.publishedDate,
                    summary: item.summary
                )
            }
        } catch {
            return []
        }
    }
    
    private static func loadSettings() -> WidgetUserSettings? {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        guard let data = defaults.data(forKey: WidgetGroupConfig.userSettingsKey),
              let settings = try? JSONDecoder().decode(WidgetUserSettings.self, from: data) else {
            return nil
        }
        return settings
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
    
    private static func buildFeedURL(from settings: WidgetUserSettings) -> URL? {
        let platform = settings.preferredPlatform
            ?? (settings.hasTistory ? .tistory : (settings.hasVelog ? .velog : nil))
        
        switch platform {
        case .tistory:
            let sourceURL = (settings.tistoryURL ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !sourceURL.isEmpty else { return nil }
            return URL(string: "\(sourceURL)/rss")
        case .velog:
            let sourceURL = settings.velogURL ?? ""
            guard let atRange = sourceURL.range(of: "@") else { return nil }
            let suffix = sourceURL[atRange.upperBound...]
            guard let id = suffix.split(separator: "/").first.map(String.init), !id.isEmpty else { return nil }
            return URL(string: "https://v2.velog.io/rss/\(id)")
        case nil:
            return nil
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
    static var title: LocalizedStringResource = "Refresh Widget"
    
    func perform() async throws -> some IntentResult {
        WidgetFeedLoader.adjustSmallPostOffset(by: 1)
        WidgetCenter.shared.reloadTimelines(ofKind: "logpocketWidget")
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
        WidgetCenter.shared.reloadTimelines(ofKind: "logpocketWidget")
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
