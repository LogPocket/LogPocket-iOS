//
//  HomeView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = HomeViewModel()
    @State private var showTutorial = false
    @State private var navigateToOnboarding = false
    @State private var pendingFocusedPostID: String?
    @State private var focusedPostID: String?
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 14) {
                    overviewCard
                    
                    VStack(spacing: 10) {
                        Picker("Platform", selection: Binding(
                            get: { viewModel.selectedPlatform },
                            set: { viewModel.selectPlatform($0) }
                        )) {
                            ForEach(BlogPlatform.allCases, id: \.self) { platform in
                                Label(platform.rawValue, systemImage: platform == .velog ? "v.square.fill" : "t.square.fill")
                                    .tag(platform)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.text.rectangle")
                                .foregroundStyle(.secondary)
                            Text("현재 블로그: \(viewModel.currentBlogIdentifier)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(viewModel.blogPosts.count)개")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.blogPosts.isEmpty {
                        emptyState
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.blogPosts) { post in
                                    BlogPostRow(
                                        post: post,
                                        isFocused: focusedPostID == post.id
                                    )
                                    .id(post.id)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        .refreshable {
                            viewModel.refreshPosts()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("LogPocket")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            navigateToOnboarding = true
                        } label: {
                            Image(systemName: "link.circle")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.refreshPosts()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showTutorial = true
                        } label: {
                            Image(systemName: "exclamationmark.circle")
                        }
                    }
                }
                .alert("링크를 입력해주세요", isPresented: $viewModel.showLinkRequiredAlert) {
                    Button("온보딩으로 이동") {
                        navigateToOnboarding = true
                    }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("해당 플랫폼 링크가 없습니다. 먼저 입력해 주세요.")
                }
                .sheet(isPresented: $showTutorial) {
                    TutorialView()
                }
                .fullScreenCover(isPresented: $navigateToOnboarding) {
                    OnboardingView(isOnboardingComplete: $navigateToOnboarding)
                        .onDisappear {
                            viewModel.refreshSettings()
                        }
                }
                .task {
                    await viewModel.syncWidgetDataOnAppActivation()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await viewModel.syncWidgetDataOnAppActivation()
                    }
                }
                .onChange(of: viewModel.blogPosts.map(\.id)) { _, _ in
                    focusPendingPost(using: proxy)
                }
                .onOpenURL { url in
                    handleDeepLink(url, using: proxy)
                }
            }
        }
    }
    
    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("오늘의 블로그", systemImage: "book.pages.fill")
                    .font(.headline)
                Spacer(minLength: 8)
                Label(viewModel.selectedPlatform.rawValue, systemImage: viewModel.selectedPlatform == .velog ? "v.square.fill" : "t.square.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.selectedPlatform == .velog ? .green : .orange)
            }
            
            Text(viewModel.currentBlogIdentifier)
                .font(.title3.weight(.bold))
                .lineLimit(1)
            
            Text("위젯에서 글을 누르면 해당 글 위치로 바로 이동해요.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.14), Color.accentColor.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
    
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("불러온 글이 없어요", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
            Text("홈을 아래로 당겨 새로고침하거나 블로그 링크를 다시 확인해 주세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func handleDeepLink(_ url: URL, using proxy: ScrollViewProxy) {
        guard url.scheme?.lowercased() == "logpocket",
              url.host == "post",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        let queries = Dictionary(
            uniqueKeysWithValues: components.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
        )
        
        guard let postURL = queries["url"], !postURL.isEmpty else { return }
        pendingFocusedPostID = postURL
        
        if let platformRaw = queries["platform"],
           let platform = BlogPlatform(deepLinkValue: platformRaw),
           platform != viewModel.selectedPlatform {
            viewModel.selectPlatform(platform)
        }
        
        focusPendingPost(using: proxy)
    }
    
    private func focusPendingPost(using proxy: ScrollViewProxy) {
        guard let postID = pendingFocusedPostID else { return }
        guard viewModel.blogPosts.contains(where: { $0.id == postID }) else { return }
        
        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
            proxy.scrollTo(postID, anchor: .center)
            focusedPostID = postID
        }
        
        pendingFocusedPostID = nil
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard focusedPostID == postID else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                focusedPostID = nil
            }
        }
    }
}

struct BlogPostRow: View {
    let post: BlogPost
    let isFocused: Bool
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            if let url = URL(string: post.url) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: post.platform == .velog ? "v.square.fill" : "t.square.fill")
                    .foregroundStyle(post.platform == .velog ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let date = post.publishedDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let summary = post.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                isFocused ? Color.accentColor.opacity(0.16) : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isFocused ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1.2)
            )
            .scaleEffect(isFocused ? 1.01 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
