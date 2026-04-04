//
//  TutorialView.swift
//  logpocket
//
//  Created by 이병찬 on 3/31/26.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    memoryWidgetCard
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
        VStack(alignment: .leading, spacing: 6) {
            Text("위젯")
                .font(.system(size: 31, weight: .bold))
            Text("홈 화면에서 바로 지난 글을 만나보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var memoryWidgetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.16))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.footnote.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("추억 위젯")
                        .font(.headline)
                    Text("매일 랜덤으로 과거에 작성한 블로그 글을\n보내드려요. 지난 회상을 앱 바깥 시선으로 추억해보세요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
            }
            
            Button {} label: {
                Text("위젯 만들기")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.95), Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            WidgetPreviewCard(family: .small, title: "내 기록", sampleTitle: "백준 1234번 - DP 풀이 정리", sampleDate: "2033. 10. 24", detailText: nil)
            WidgetPreviewCard(family: .medium, title: nil, sampleTitle: "백준 1234번 - DP 풀이 정리", sampleDate: "2033. 10. 24", detailText: "제주도 여행 3일차 기록")
            WidgetPreviewCard(family: .large, title: "추억 회선", sampleTitle: "백준 1234번 - DP 풀이 정리", sampleDate: "2023. 10. 24", detailText: "동적 계획법(Dynamic Programming)을 활용하여 백준 1234번 문제를 해결하는 방법을 정리했다. 상태 정의와 점화식 구성, 초기값 설정부터 복잡도 최적화 포인트까지 기본을 이해하기 쉽게 작성했다.")
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.22), lineWidth: 1)
        )
    }
}

struct TutorialStep: View {
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

struct WidgetPreviewCard: View {
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
        
        // iPhone widget ratio:
        // small 155x155, medium 329x155, large 329x345
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
    let title: String?
    let sampleTitle: String
    let sampleDate: String
    let detailText: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(family.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.green.opacity(0.18))
                        .frame(width: 20, height: 20)
                        .overlay {
                            Text("V")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                    
                    if let title {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(sampleTitle)
                    .font(.headline)
                    .lineLimit(family == .small ? 2 : nil)
                
                Text(sampleDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let detailText {
                    Text(detailText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .lineLimit(family == .medium ? 1 : nil)
                }
            }
            .padding(14)
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
}

#Preview {
    TutorialView()
}
