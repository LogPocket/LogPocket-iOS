//
//  HomeView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showTutorial = false
    @State private var navigateToOnboarding = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.blogPosts) { post in
                                BlogPostRow(post: post)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
            }
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
        }
    }
}

struct BlogPostRow: View {
    let post: BlogPost
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
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
