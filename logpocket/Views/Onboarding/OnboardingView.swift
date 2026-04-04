//
//  OnboardingView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    
                    platformInputCard(
                        platform: .velog,
                        title: "Velog",
                        symbol: "v.square.fill",
                        tint: .green,
                        hint: "Velog 아이디 입력",
                        prefix: "velog.io/@",
                        suffix: "/posts",
                        text: $viewModel.velogID
                    )
                    
                    platformInputCard(
                        platform: .tistory,
                        title: "Tistory",
                        symbol: "t.square.fill",
                        tint: .orange,
                        hint: "Tistory 아이디 입력",
                        prefix: "",
                        suffix: ".tistory.com",
                        text: $viewModel.tistoryID
                    )
                    
                    Button {
                        viewModel.saveSettings {
                            isOnboardingComplete = true
                            dismiss()
                        }
                    } label: {
                        Text("완료")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(
                        Color.accentColor,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .opacity(viewModel.isCompleteButtonEnabled ? 1 : 0.5)
                    .disabled(!viewModel.isCompleteButtonEnabled)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("블로그 링크 설정")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("티스토리 혹은 Velog 아이디를\n하나 이상 입력해 주세요")
                .font(.title2.weight(.bold))
            Text("아이디만 입력하면 링크는 자동으로 생성됩니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func platformInputCard(
        platform: BlogPlatform,
        title: String,
        symbol: String,
        tint: Color,
        hint: String,
        prefix: String,
        suffix: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
            }
            
            HStack(spacing: 6) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                TextField("", text: text, prompt: Text(hint).foregroundStyle(.gray))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .onChange(of: text.wrappedValue) { newValue in
                        text.wrappedValue = viewModel.sanitizeID(newValue, for: platform)
                    }
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if let previewURL = viewModel.normalizedURLFromID(
                text.wrappedValue,
                for: platform
            ) {
                Text(previewURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
