//
//  TutorialView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    highlightsCard
                    widgetStepsCard
                    previewSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Text("뒤로")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("위젯 사용 가이드", systemImage: "rectangle.grid.2x2.fill")
                .font(.title3.weight(.bold))
            Text("대형 위젯은 글 한 개를 크게 보여주고, Velog/Tistory를 바로 전환할 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("핵심 변경점")
                .font(.headline)
            featureRow(icon: "arrow.triangle.2.circlepath.circle.fill", text: "위젯에서 새로고침으로 최신 글 즉시 반영")
            featureRow(icon: "line.3.horizontal.decrease.circle.fill", text: "대형 위젯에서 Velog/Tistory 바로 선택")
            featureRow(icon: "location.fill", text: "위젯 글 탭 시 앱 내 해당 글 위치로 스크롤 + 포커스")
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var widgetStepsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("위젯 추가 방법")
                .font(.headline)
            TutorialStep(number: 1, text: "홈 화면을 길게 누르세요")
            TutorialStep(number: 2, text: "왼쪽 상단 + 버튼을 탭하세요")
            TutorialStep(number: 3, text: "'LogPocket'를 검색하세요")
            TutorialStep(number: 4, text: "원하는 크기를 선택하고 추가하세요")
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("위젯 미리보기")
                .font(.title3.bold())
            
            WidgetPreviewCard(family: .small)
            WidgetPreviewCard(family: .medium)
            WidgetPreviewCard(family: .large)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.22), lineWidth: 1)
        )
    }
}

private struct TutorialStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(number)")
                .font(.caption2.bold())
                .foregroundStyle(Color.accentColor)
                .frame(width: 16, height: 16)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            Text(text)
                .font(.subheadline)
        }
    }
}

private struct WidgetPreviewCard: View {
    enum Family {
        case small
        case medium
        case large
        
        var label: String {
            switch self {
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large"
            }
        }
        
        var previewWidth: CGFloat {
            switch self {
            case .small: return 132
            case .medium, .large: return 280
            }
        }
        
        var previewHeight: CGFloat {
            switch self {
            case .small: return 132
            case .medium: return 132
            case .large: return 294
            }
        }
    }
    
    let family: Family
    
    var body: some View {
        VStack(spacing: 8) {
            Text(family.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Group {
                switch family {
                case .small:
                    smallPreview
                case .medium:
                    mediumPreview
                case .large:
                    largePreview
                }
            }
            .padding(12)
            .frame(width: family.previewWidth, height: family.previewHeight, alignment: .topLeading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var smallPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Velog", systemImage: "v.square.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(.green)
            }
            Text("백준 1234번 - DP 풀이 정리")
                .font(.caption.weight(.semibold))
                .lineLimit(3)
            Text("업데이트 1m")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
    
    private var mediumPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Velog 최근 글", systemImage: "v.square.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(.green)
            }
            
            ForEach(1...5, id: \.self) { idx in
                HStack(spacing: 6) {
                    Text("\(idx)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                        .frame(width: 10, alignment: .leading)
                    Text(idx == 1 ? "백준 1234번 - DP 풀이 정리" : "SwiftUI 상태 관리 정리")
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text("10/24")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var largePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Velog 집중 보기", systemImage: "v.square.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
                Text("1/8 · 업데이트 1m")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 6) {
                platformChip(title: "Velog", isSelected: true, tint: .green)
                platformChip(title: "Tistory", isSelected: false, tint: .orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("앱에서 바로 이동", systemImage: "location.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                    Spacer()
                    Text("2023.10.24")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text("백준 1234번 - DP 풀이 정리")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                
                Text("동적 계획법으로 문제를 해결한 과정을 요약해요. 위젯에서 탭하면 앱의 해당 글 위치로 즉시 스크롤되고 색상 포커스로 확인할 수 있어요.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
            .padding(10)
            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                navChip(title: "이전", symbol: "chevron.left")
                navChip(title: "다음", symbol: "chevron.right")
            }
        }
    }
    
    private func platformChip(title: String, isSelected: Bool, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isSelected ? tint : .secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                isSelected ? tint.opacity(0.18) : Color(.secondarySystemBackground),
                in: Capsule()
            )
    }
    
    private func navChip(title: String, symbol: String) -> some View {
        HStack(spacing: 4) {
            if title == "이전" { Image(systemName: symbol) }
            Text(title)
                .font(.caption2.weight(.semibold))
            if title == "다음" { Image(systemName: symbol) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .foregroundStyle(.white)
        .background(Color.green.opacity(0.8), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    TutorialView()
}
