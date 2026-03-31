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
                VStack(alignment: .leading, spacing: 20) {
                    Text("위젯 UI 예시 & 설정 방법")
                        .font(.title2.bold())
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TutorialStep(number: 1, title: "홈 화면 길게 누르기", description: "빈 공간을 길게 눌러 편집 모드로 들어가세요.")
                        TutorialStep(number: 2, title: "+ 버튼 누르기", description: "좌측 상단의 + 버튼을 눌러 위젯 목록을 엽니다.")
                        TutorialStep(number: 3, title: "LogPocket 검색", description: "검색창에서 LogPocket을 검색해 선택하세요.")
                        TutorialStep(number: 4, title: "위젯 추가", description: "원하는 크기를 선택 후 위젯 추가를 누르세요.")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("위젯 미리보기")
                            .font(.headline)
                        WidgetPreview(size: "Small", description: "최신 글 1개")
                        WidgetPreview(size: "Medium", description: "최신 글 2~3개")
                        WidgetPreview(size: "Large", description: "최신 글 4~5개")
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("튜토리얼")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TutorialStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct WidgetPreview: View {
    let size: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
                .frame(width: 62, height: 62)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.caption)
                        Text(size).font(.caption2.bold())
                    }
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(size) 위젯")
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    TutorialView()
}
