//
//  OnboardingView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct OnboardingView: View {
    private enum InputField: Hashable {
        case velog
        case tistory
    }
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    @FocusState private var focusedField: InputField?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickGuide
                    statusRow
                    
                    platformInputCard(
                        platform: .velog,
                        field: .velog,
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
                        field: .tistory,
                        title: "Tistory",
                        symbol: "t.square.fill",
                        tint: .orange,
                        hint: "Tistory 아이디 입력",
                        prefix: "",
                        suffix: ".tistory.com",
                        text: $viewModel.tistoryID
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("블로그 연결")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                completeButton
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("블로그를 연결해 주세요", systemImage: "link.circle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            
            Text("아이디만 입력하면 주소는 자동 완성되고, 위젯 데이터도 바로 동기화됩니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var quickGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("입력 가이드")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text("• ID 또는 전체 링크 모두 입력 가능\n• 하나 이상 입력하면 완료할 수 있어요")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var statusRow: some View {
        HStack(spacing: 8) {
            statusChip(title: "Velog", isValid: !viewModel.sanitizeID(viewModel.velogID, for: .velog).isEmpty, tint: .green)
            statusChip(title: "Tistory", isValid: !viewModel.sanitizeID(viewModel.tistoryID, for: .tistory).isEmpty, tint: .orange)
        }
    }
    
    private func statusChip(title: String, isValid: Bool, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isValid ? tint : .secondary)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isValid ? .primary : .secondary)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }
    
    private var completeButton: some View {
        Button(action: handleComplete) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("완료하고 시작하기")
                    .fontWeight(.semibold)
                Spacer(minLength: 6)
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
        .controlSize(.large)
        .disabled(!viewModel.isCompleteButtonEnabled)
        .contentShape(Rectangle())
    }
    
    private func handleComplete() {
        guard viewModel.isCompleteButtonEnabled else { return }
        viewModel.saveSettings {
            isOnboardingComplete = true
            dismiss()
        }
    }
    
    private func platformInputCard(
        platform: BlogPlatform,
        field: InputField,
        title: String,
        symbol: String,
        tint: Color,
        hint: String,
        prefix: String,
        suffix: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text("아이디 또는 링크")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                if !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack(spacing: 8) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                TextField("", text: text, prompt: Text(hint).foregroundStyle(.gray))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: field)
                    .submitLabel(field == .velog ? .next : .done)
                    .onSubmit {
                        focusedField = field == .velog ? .tistory : nil
                    }
                    .onChange(of: text.wrappedValue) { newValue in
                        let sanitized = viewModel.sanitizeID(newValue, for: platform)
                        if sanitized != newValue {
                            text.wrappedValue = sanitized
                        }
                    }
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
