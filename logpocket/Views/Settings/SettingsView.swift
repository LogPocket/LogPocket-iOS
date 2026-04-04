//
//  SettingsView.swift
//  logpocket
//
//  Created by GitHub Copilot CLI
//

import Combine
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    blogSettingsSection
                    
                    if viewModel.settings.hasTistory {
                        tistoryCategorySection
                    }
                    
                    widgetSettingsSection
                }
                .padding(20)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        viewModel.saveSettings { dismiss() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var blogSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("블로그 설정")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Tistory 블로그").font(.subheadline).foregroundStyle(.secondary)
                TextField("https://yourblog.tistory.com", text: $viewModel.tistoryURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Velog 블로그").font(.subheadline).foregroundStyle(.secondary)
                TextField("https://velog.io/@username", text: $viewModel.velogURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var tistoryCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tistory 카테고리").font(.headline)
            Text("특정 카테고리의 글만 표시하려면 입력하세요. 비워두면 전체 글이 표시됩니다.")
                .font(.caption).foregroundStyle(.secondary)
            
            TextField("카테고리 이름 (예: 개발/일상)", text: $viewModel.tistoryCategory)
                .textFieldStyle(.roundedBorder)
            
            if !viewModel.tistoryCategory.isEmpty {
                Text("카테고리: \(viewModel.tistoryCategory)")
                    .font(.caption).foregroundStyle(.blue)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var widgetSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("위젯 설정").font(.headline)
            Text("위젯이 기본으로 표시할 플랫폼을 선택하세요.")
                .font(.caption).foregroundStyle(.secondary)
            
            VStack(spacing: 10) {
                if viewModel.settings.hasTistory {
                    widgetPlatformButton(platform: .tistory, isSelected: viewModel.widgetPreferredPlatform == .tistory)
                }
                if viewModel.settings.hasVelog {
                    widgetPlatformButton(platform: .velog, isSelected: viewModel.widgetPreferredPlatform == .velog)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func widgetPlatformButton(platform: BlogPlatform, isSelected: Bool) -> some View {
        Button { viewModel.widgetPreferredPlatform = platform } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                Text(platform.rawValue).font(.body).foregroundStyle(.primary)
                Spacer()
                platformBadge(for: platform)
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
        }
    }
    
    private func platformBadge(for platform: BlogPlatform) -> some View {
        let (icon, color): (String, Color) = {
            switch platform {
            case .tistory: return ("T", Color(red: 251/255, green: 140/255, blue: 0/255))
            case .velog: return ("V", Color(red: 32/255, green: 201/255, blue: 151/255))
            }
        }()
        
        return RoundedRectangle(cornerRadius: 5, style: .continuous).fill(color).frame(width: 24, height: 24)
            .overlay { Text(icon).font(.caption.bold()).foregroundStyle(.white) }
    }
}

class SettingsViewModel: ObservableObject {
    @Published var tistoryURL: String = ""
    @Published var velogURL: String = ""
    @Published var tistoryCategory: String = ""
    @Published var widgetPreferredPlatform: BlogPlatform?
    var settings: UserSettings
    
    init() {
        settings = UserDefaultsManager.shared.loadSettings()
        tistoryURL = settings.tistoryURL ?? ""
        velogURL = settings.velogURL ?? ""
      
    }
    
    func saveSettings(completion: @escaping () -> Void) {
        var updatedSettings = settings
        let trimmedTistory = tistoryURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedVelog = velogURL.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSettings.tistoryURL = trimmedTistory.isEmpty ? nil : trimmedTistory
        updatedSettings.velogURL = trimmedVelog.isEmpty ? nil : trimmedVelog
        let trimmedCategory = tistoryCategory.trimmingCharacters(in: .whitespacesAndNewlines)
       
        UserDefaultsManager.shared.saveSettings(updatedSettings)
        completion()
    }
}
