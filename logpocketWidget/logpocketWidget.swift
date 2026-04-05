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
    static let selectedPlatformKey = "widgetSelectedPlatform"
    static let appDeepLinkScheme = "logpocket"
    static let appDeepLinkHost = "post"
    static let largePostOffsetKey = "widgetLargePostOffset"
    static let smallPostOffsetKey = "widgetSmallPostOffset"
    static let mediumPostOffsetKey = "widgetMediumPostOffset"
    static let cachedPostsTistoryKey = "widgetCachedPostsTistory"
    static let cachedPostsVelogKey = "widgetCachedPostsVelog"
    static let cachedUpdatedAtTistoryKey = "widgetCachedUpdatedAtTistory"
    static let cachedUpdatedAtVelogKey = "widgetCachedUpdatedAtVelog"
    static let maxPosts = 40
}

enum WidgetPlatform: String, Codable {
    case tistory = "Tistory"
    case velog = "Velog"
    
    var deepLinkValue: String {
        switch self {
        case .tistory:
            return "tistory"
        case .velog:
            return "velog"
        }
    }
    
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
    let mediumPostOffset: Int
    let platform: WidgetPlatform?
    let lastUpdatedAt: Date?
    let isFromCache: Bool
    /// 티스토리·벨로그 둘 다 연결된 경우에만 `true` (세그먼트 표시).
    let supportsPlatformSegment: Bool
    /// 세그먼트에서 강조할 플랫폼 (`supportsPlatformSegment`일 때만 사용).
    let platformSegmentSelection: WidgetPlatform
    /// 설정은 있으나 티스토리·벨로그 중 하나만 등록된 경우 (스몰·미디엄·라지 공통 안내).
    let incompleteDualPlatformRegistration: Bool
}

struct LogPocketProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogPocketEntry {
        LogPocketEntry(
            date: .now,
            posts: samplePosts,
            errorMessage: nil,
            largePostOffset: 0,
            smallPostOffset: 0,
            mediumPostOffset: 0,
            platform: .velog,
            lastUpdatedAt: .now,
            isFromCache: false,
            supportsPlatformSegment: true,
            platformSegmentSelection: .velog,
            incompleteDualPlatformRegistration: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LogPocketEntry) -> Void) {
        Task {
            let result = await WidgetFeedLoader.loadFeed()
            let posts = context.isPreview && result.posts.isEmpty ? samplePosts : result.posts
            let offset = WidgetFeedLoader.loadLargePostOffset()
            let smallOffset = WidgetFeedLoader.loadSmallPostOffset()
            let mediumOffset = WidgetFeedLoader.loadMediumPostOffset()
            let dual = WidgetFeedLoader.dualPlatformLinked()
            let segmentPick = WidgetFeedLoader.platformForSegmentHighlight(feedResult: result)
            let incomplete = WidgetFeedLoader.incompleteDualPlatformRegistration()
            
            completion(
                LogPocketEntry(
                    date: .now,
                    posts: posts,
                    errorMessage: result.errorMessage,
                    largePostOffset: offset,
                    smallPostOffset: smallOffset,
                    mediumPostOffset: mediumOffset,
                    platform: result.platform,
                    lastUpdatedAt: result.lastUpdatedAt,
                    isFromCache: result.isFromCache,
                    supportsPlatformSegment: dual,
                    platformSegmentSelection: segmentPick,
                    incompleteDualPlatformRegistration: incomplete
                )
            )
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LogPocketEntry>) -> Void) {
        Task {
            let result = await WidgetFeedLoader.loadFeed()
            let offset = WidgetFeedLoader.loadLargePostOffset()
            let smallOffset = WidgetFeedLoader.loadSmallPostOffset()
            let mediumOffset = WidgetFeedLoader.loadMediumPostOffset()
            let dual = WidgetFeedLoader.dualPlatformLinked()
            let segmentPick = WidgetFeedLoader.platformForSegmentHighlight(feedResult: result)
            let incomplete = WidgetFeedLoader.incompleteDualPlatformRegistration()
            
            let entry = LogPocketEntry(
                date: .now,
                posts: result.posts,
                errorMessage: result.errorMessage,
                largePostOffset: offset,
                smallPostOffset: smallOffset,
                mediumPostOffset: mediumOffset,
                platform: result.platform,
                lastUpdatedAt: result.lastUpdatedAt,
                isFromCache: result.isFromCache,
                supportsPlatformSegment: dual,
                platformSegmentSelection: segmentPick,
                incompleteDualPlatformRegistration: incomplete
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
    
    /// 위젯 공통 숫자만 날짜 (예: 26.4.2)
    private static let widgetNumericDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yy.M.d"
        return f
    }()
    
    private func widgetNumericDateString(_ date: Date?) -> String {
        guard let date else { return "-" }
        return Self.widgetNumericDateFormatter.string(from: date)
    }
    
    /// 제목 앞의 `[프로그래머스]` 등 대괄호 태그 제거 (위젯 표시용)
    private func widgetDisplayTitle(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^\\[[^\\]]+\\]\\s*"
        while let range = s.range(of: pattern, options: .regularExpression) {
            s.removeSubrange(range)
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s.isEmpty ? raw : s
    }
    
    private var dualPlatformRegistrationMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LogPocket", systemImage: "book.pages")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text("등록이 안되어있습니다")
                .font(.subheadline.weight(.semibold))
            Text("티스토리와 벨로그를 모두 앱에서 등록해 주세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var accentColor: Color {
        switch family {
        case .systemSmall:
            return selectedSmallPost?.platform.tint ?? entry.platform?.tint ?? .accentColor
        case .systemMedium:
            return mediumLeadPost?.platform.tint ?? entry.platform?.tint ?? .accentColor
        default:
            return focusedLargePost?.platform.tint ?? entry.platform?.tint ?? .accentColor
        }
    }
    
    private var platformLabel: String {
        if entry.platform != nil {
            return entry.platform!.rawValue
        }
        if !entry.posts.isEmpty {
            return "최근 글"
        }
        return "Blog"
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
    
    private var focusedLargePost: WidgetPost? {
        guard !entry.posts.isEmpty else { return nil }
        return entry.posts[largeIndex]
    }
    
    private var largeProgressLabel: String {
        guard !entry.posts.isEmpty else { return "0/0" }
        return "\(largeIndex + 1)/\(entry.posts.count)"
    }
    
    private var mediumStartIndex: Int {
        guard !entry.posts.isEmpty else { return 0 }
        let count = entry.posts.count
        return ((entry.mediumPostOffset % count) + count) % count
    }
    
    private var mediumLeadPost: WidgetPost? {
        guard !entry.posts.isEmpty else { return nil }
        return entry.posts[mediumStartIndex]
    }
    
    private struct RankedWidgetPost: Identifiable {
        let post: WidgetPost
        let rank: Int
        var id: String { post.id }
    }
    
    private var largeRelatedPosts: [RankedWidgetPost] {
        guard !entry.posts.isEmpty else { return [] }
        let limit = min(3, max(0, entry.posts.count - 1))
        guard limit > 0 else { return [] }
        
        return (1...limit).map { offset in
            let index = (largeIndex + offset) % entry.posts.count
            return RankedWidgetPost(
                post: entry.posts[index],
                rank: offset + 1
            )
        }
    }
    
    private var smallWidget: some View {
        Group {
            if entry.incompleteDualPlatformRegistration {
                dualPlatformRegistrationMessage
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if let post = selectedSmallPost {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        headerBadge(label: platformLabel, detail: "\(smallIndex + 1)/\(entry.posts.count)")
                        
                        Text(widgetDisplayTitle(post.title))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.92)
                        
                        Text(contentDigest(for: post))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if entry.isFromCache {
                            Text("캐시")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                    
                    smallWidgetBottomBar(post: post)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    emptyState
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                    smallWidgetBottomBar(post: nil)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(
            entry.incompleteDualPlatformRegistration ? nil : selectedSmallPost.flatMap { appDeepLink(for: $0) }
        )
    }
    
    @ViewBuilder
    private func smallWidgetBottomBar(post: WidgetPost?) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if let post {
                Text(widgetNumericDateString(post.publishedDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }
            
            HStack(spacing: 6) {
                if let post, entry.supportsPlatformSegment {
                    Button(intent: ToggleWidgetPlatformIntent()) {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
                Button(intent: ChangeSmallPostIntent()) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
    
    private var mediumWidget: some View {
        Group {
            if entry.incompleteDualPlatformRegistration {
                dualPlatformRegistrationMessage
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if entry.posts.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    mediumWidgetHeaderRow
                    
                    if let lead = mediumLeadPost {
                        mediumCompactFeaturedPost(lead)
                            .padding(.top, 6)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(intent: ChangeMediumPostIntent()) {
                        HStack(spacing: 4) {
                            Text("다음 글")
                                .font(.caption2.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var mediumProgressLabel: String {
        guard !entry.posts.isEmpty else { return "0/0" }
        return "\(mediumStartIndex + 1)/\(entry.posts.count)"
    }
    
    private var mediumWidgetHeaderRow: some View {
        HStack(alignment: .center, spacing: 5) {
            Text("글 모아보기")
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            if entry.supportsPlatformSegment {
                widgetPlatformSegmentedControl
                    .fixedSize(horizontal: true, vertical: false)
            }
            if !entry.posts.isEmpty {
                Text(mediumProgressLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var widgetPlatformSegmentedControl: some View {
        HStack(spacing: 1) {
            widgetPlatformSegmentButton(.velog)
            widgetPlatformSegmentButton(.tistory)
        }
        .padding(2)
        .background(Color.primary.opacity(0.12), in: Capsule())
    }
    
    private func widgetPlatformSegmentButton(_ platform: WidgetPlatform) -> some View {
        let selected = entry.platformSegmentSelection == platform
        return Button(intent: SetWidgetPlatformIntent(platform: platform)) {
            Image(systemName: platform.symbolName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(selected ? platform.tint : .secondary)
                .frame(width: 26, height: 18)
                .background(
                    selected ? platform.tint.opacity(0.25) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func mediumCompactFeaturedPost(_ post: WidgetPost) -> some View {
        if let destination = appDeepLink(for: post) {
            Link(destination: destination) {
                mediumCompactFeaturedCard(post)
            }
        } else {
            mediumCompactFeaturedCard(post)
        }
    }
    
    private func mediumCompactFeaturedCard(_ post: WidgetPost) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(post.platform.tint)
                .frame(width: 3, height: 44)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(widgetDisplayTitle(post.title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.88)
                
                Text(contentDigest(for: post))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)
                
                Text(widgetNumericDateString(post.publishedDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(post.platform.tint.opacity(0.28), lineWidth: 1)
        )
    }
    
    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.incompleteDualPlatformRegistration {
                dualPlatformRegistrationMessage
                Spacer(minLength: 0)
            } else {
            largeWidgetHeaderRow
            
            if let primary = focusedLargePost {
                largeFocusedPost(primary)
                
                if !largeRelatedPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("관련 글")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        ForEach(largeRelatedPosts) { item in
                            largeRelatedPostRow(post: item.post, rank: item.rank)
                        }
                    }
                }
                
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
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var largeWidgetHeaderRow: some View {
        HStack(alignment: .center, spacing: 6) {
            Text("글 보기")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            if entry.supportsPlatformSegment {
                widgetPlatformSegmentedControl
                    .fixedSize(horizontal: true, vertical: false)
            }
            if !entry.posts.isEmpty {
                Text(largeProgressLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button(intent: RefreshWidgetTimelineIntent()) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func largeFocusedPost(_ post: WidgetPost) -> some View {
        if let destination = appDeepLink(for: post) {
            Link(destination: destination) {
                largeFocusedCard(post)
            }
        } else {
            largeFocusedCard(post)
        }
    }
    
    private func largeFocusedCard(_ post: WidgetPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Label("앱에서 바로 이동", systemImage: "location.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accentColor)
                Spacer(minLength: 6)
                Text(widgetNumericDateString(post.publishedDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text(widgetDisplayTitle(post.title))
                .font(.headline.weight(.semibold))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Text(contentDigest(for: post))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
            
            if entry.isFromCache {
                Text("캐시")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            if post.summary == nil || post.summary?.isEmpty == true {
                Text("요약이 없는 글은 제목 기반으로 핵심을 정리해 보여줘요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.16), accentColor.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
    
    @ViewBuilder
    private func largeRelatedPostRow(post: WidgetPost, rank: Int) -> some View {
        if let destination = appDeepLink(for: post) {
            Link(destination: destination) {
                largeRelatedContent(post: post, rank: rank)
            }
        } else {
            largeRelatedContent(post: post, rank: rank)
        }
    }
    
    private func largeRelatedContent(post: WidgetPost, rank: Int) -> some View {
        HStack(spacing: 7) {
            Text("\(rank)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(accentColor)
                .frame(width: 10, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(widgetDisplayTitle(post.title))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(contentDigest(for: post))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            Text(widgetNumericDateString(post.publishedDate))
                .font(.caption2)
                .foregroundStyle(.secondary)
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
    
    private func appDeepLink(for post: WidgetPost) -> URL? {
        var components = URLComponents()
        components.scheme = WidgetGroupConfig.appDeepLinkScheme
        components.host = WidgetGroupConfig.appDeepLinkHost
        components.queryItems = [
            URLQueryItem(name: "url", value: post.url),
            URLQueryItem(name: "platform", value: post.platform.deepLinkValue)
        ]
        return components.url
    }
    
    private func contentDigest(for post: WidgetPost) -> String {
        if let summary = post.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
           summary.count >= 18 {
            return truncated(summary, limit: 130)
        }
        
        let normalizedTitle = widgetDisplayTitle(post.title)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return "이 글은 \(truncated(normalizedTitle, limit: 42))에 대한 핵심 내용을 다뤄요."
    }
    
    private func truncated(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        let head = text.prefix(limit)
        return "\(head)…"
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
        
        guard let settings else {
            let cached = loadCachedSnapshot(preferred: nil)
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
        
        let resolvedPlatform = resolvePlatform(from: settings)
        let cached = loadCachedSnapshot(preferred: resolvedPlatform)
        
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
    
    /// 두 플랫폼 URL이 모두 비어 있지 않으면 세그먼트 표시.
    /// (`buildFeedURL` 성공 여부와 무관 — 파싱 실패 시에도 전환 UI는 보이게 함)
    static func dualPlatformLinked() -> Bool {
        guard let settings = loadSettings() else { return false }
        return settings.hasTistory && settings.hasVelog
    }
    
    /// 앱 설정이 있는데 티스토리·벨로그 중 하나만 채워진 경우.
    static func incompleteDualPlatformRegistration() -> Bool {
        guard let settings = loadSettings() else { return false }
        return !(settings.hasTistory && settings.hasVelog)
    }
    
    static func toggleWidgetPlatform() {
        guard dualPlatformLinked() else { return }
        let current = loadSelectedPlatform()
            ?? loadSettings()?.preferredPlatform
            ?? .tistory
        let next: WidgetPlatform = (current == .velog) ? .tistory : .velog
        setSelectedPlatform(next)
    }
    
    static func platformForSegmentHighlight(feedResult: WidgetFeedResult) -> WidgetPlatform {
        if let p = feedResult.platform { return p }
        if let s = loadSelectedPlatform() { return s }
        guard let settings = loadSettings() else { return .velog }
        if let pref = settings.preferredPlatform,
           buildFeedURL(from: settings, platform: pref) != nil {
            return pref
        }
        if buildFeedURL(from: settings, platform: .tistory) != nil { return .tistory }
        return .velog
    }
    
    private static func resolvePlatform(from settings: WidgetUserSettings) -> WidgetPlatform? {
        if let selected = loadSelectedPlatform(),
           buildFeedURL(from: settings, platform: selected) != nil {
            return selected
        }
        
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
    
    static func setSelectedPlatform(_ platform: WidgetPlatform) {
        guard let defaults = sharedDefaults() else { return }
        defaults.set(platform.deepLinkValue, forKey: WidgetGroupConfig.selectedPlatformKey)
        defaults.set(0, forKey: WidgetGroupConfig.largePostOffsetKey)
        defaults.set(0, forKey: WidgetGroupConfig.smallPostOffsetKey)
        defaults.set(0, forKey: WidgetGroupConfig.mediumPostOffsetKey)
    }
    
    private static func loadSelectedPlatform() -> WidgetPlatform? {
        guard let defaults = sharedDefaults(),
              let raw = defaults.string(forKey: WidgetGroupConfig.selectedPlatformKey) else {
            return nil
        }
        return platform(from: raw)
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
    
    static func loadMediumPostOffset() -> Int {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        return defaults.integer(forKey: WidgetGroupConfig.mediumPostOffsetKey)
    }
    
    static func adjustMediumPostOffset(by delta: Int) {
        let defaults = UserDefaults(suiteName: WidgetGroupConfig.suiteName) ?? .standard
        let current = defaults.integer(forKey: WidgetGroupConfig.mediumPostOffsetKey)
        defaults.set(current + delta, forKey: WidgetGroupConfig.mediumPostOffsetKey)
    }
    
    private static func makePosts(from items: [WidgetRSSItem], platform: WidgetPlatform) -> [WidgetPost] {
        let posts = items.compactMap { item -> WidgetPost? in
            guard let title = item.title, let link = item.link else { return nil }
            let summary = normalizedSummary(title: title, rawSummary: item.summary)
            return WidgetPost(
                id: link,
                title: title,
                url: link,
                platform: platform,
                publishedDate: item.publishedDate,
                summary: summary
            )
        }
        
        return posts.sorted { left, right in
            (left.publishedDate ?? .distantPast) > (right.publishedDate ?? .distantPast)
        }
    }
    
    private static func normalizedSummary(title: String, rawSummary: String?) -> String? {
        guard let rawSummary else { return nil }
        
        var cleaned = rawSummary
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else { return nil }
        
        if cleaned.caseInsensitiveCompare(title) == .orderedSame {
            return nil
        }
        
        if cleaned.lowercased().hasPrefix(title.lowercased()) {
            cleaned = String(cleaned.dropFirst(title.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !cleaned.isEmpty else { return nil }
        
        if let sentence = firstSentence(in: cleaned), sentence.count >= 14 {
            return sentence
        }
        
        return truncatedSummary(cleaned, limit: 140)
    }
    
    private static func firstSentence(in text: String) -> String? {
        let separators = ["다.", ". ", "! ", "? ", "요.", "\n"]
        
        for separator in separators {
            if let range = text.range(of: separator) {
                let candidate = String(text[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.count >= 14 {
                    return truncatedSummary(candidate, limit: 120)
                }
            }
        }
        
        return nil
    }
    
    private static func truncatedSummary(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return "\(text.prefix(limit))…"
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

enum WidgetPlatformSelection: String, AppEnum {
    case tistory
    case velog
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Platform")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .tistory: "Tistory",
        .velog: "Velog"
    ]
    
    var platform: WidgetPlatform {
        switch self {
        case .tistory:
            return .tistory
        case .velog:
            return .velog
        }
    }
}

struct SetWidgetPlatformIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Widget Platform"
    
    @Parameter(title: "Platform")
    var platform: WidgetPlatformSelection
    
    init() {
        platform = .velog
    }
    
    init(platform: WidgetPlatform) {
        self.platform = platform == .tistory ? .tistory : .velog
    }
    
    func perform() async throws -> some IntentResult {
        WidgetFeedLoader.setSelectedPlatform(platform.platform)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGroupConfig.widgetKind)
        return .result()
    }
}

struct ToggleWidgetPlatformIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Widget Platform"
    
    func perform() async throws -> some IntentResult {
        WidgetFeedLoader.toggleWidgetPlatform()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGroupConfig.widgetKind)
        return .result()
    }
}

struct RefreshWidgetTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget Data"
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGroupConfig.widgetKind)
        return .result()
    }
}

struct ChangeSmallPostIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Small Widget Post"
    
    func perform() async throws -> some IntentResult {
        WidgetFeedLoader.adjustSmallPostOffset(by: 1)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetGroupConfig.widgetKind)
        return .result()
    }
}

struct ChangeMediumPostIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Medium Widget Posts"
    
    func perform() async throws -> some IntentResult {
        WidgetFeedLoader.adjustMediumPostOffset(by: 1)
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
