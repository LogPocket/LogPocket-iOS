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
            Text("스몰은 하단에서 날짜·플랫폼 전환(둘 다 등록 시)·글 순환 버튼을 쓰고, 미디엄·라지는 상단에서 진행도·Velog/티스토리 세그먼트·타임라인 새로고침을 써요. 미디엄은 대표 글 한 장과 다음 글, 대형은 본문·관련 글·이전/다음이에요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("핵심 기능")
                .font(.headline)
            featureRow(icon: "arrow.clockwise", text: "미디엄·라지 헤더 새로고침으로 타임라인 갱신 (스몰 하단 동그란 버튼은 같은 피드에서 다음 글로 순환)")
            featureRow(icon: "arrow.left.arrow.right.circle.fill", text: "티스토리·벨로그 둘 다 등록 시: 스몰 ↔ 버튼, 미디엄·라지는 세그먼트로 전환")
            featureRow(icon: "calendar", text: "날짜는 숫자만 표시 (예: 26.4.2)")
            featureRow(icon: "location.fill", text: "글 영역 탭 시 앱에서 해당 글 위치로 스크롤·포커스")
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
            case .medium: return 158
            case .large: return 312
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
            .padding(family == .small ? 0 : 10)
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
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "v.square.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                    Text("Velog")
                        .font(.system(size: 10, weight: .semibold))
                    Spacer(minLength: 4)
                    Text("1/8")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Text("백준 1234번 - DP 풀이")
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text("메모이제이션으로…")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, 6)
            
            HStack(alignment: .center, spacing: 6) {
                Text("26.4.5")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.green)
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }
    
    private var mediumPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                Text("글 모아보기")
                    .font(.system(size: 9, weight: .semibold))
                Spacer(minLength: 4)
                miniPlatformSegment(selectedVelog: true)
                Text("1/8")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green)
            }
            
            HStack(alignment: .top, spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.green)
                    .frame(width: 3, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("백준 1234번 - DP 풀이")
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(2)
                    Text("메모이제이션으로 핵심만 정리한…")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("26.4.5")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.28), lineWidth: 1)
            )
            .padding(.top, 6)
            
            Spacer(minLength: 2)
            
            HStack(spacing: 4) {
                Text("다음 글")
                    .font(.system(size: 9, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding(.top, 4)
        }
    }
    
    private var largePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 4) {
                Text("글 보기")
                    .font(.system(size: 9, weight: .semibold))
                Spacer(minLength: 4)
                miniPlatformSegment(selectedVelog: true)
                Text("1/8")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Label("앱에서 바로 이동", systemImage: "location.fill")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.green)
                    Spacer(minLength: 4)
                    Text("26.4.5")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
                Text("백준 1234번 - DP 풀이")
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(2)
                Text("동적 계획법으로 문제를 해결한 과정을 요약해요.")
                    .font(.system(size: 7))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.16), Color.green.opacity(0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("관련 글")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                largeRelatedPreviewRow(rank: 2, title: "카카오 기출 정리", digest: "이분 탐색·그리디", date: "26.4.1")
                largeRelatedPreviewRow(rank: 3, title: "Swift Observable", digest: "상태와 바인딩", date: "26.3.28")
            }
            
            HStack(spacing: 6) {
                largeNavGradientButton(title: "이전", symbol: "chevron.left", isLeading: true)
                largeNavGradientButton(title: "다음", symbol: "chevron.right", isLeading: false)
            }
        }
    }
    
    private func miniPlatformSegment(selectedVelog: Bool) -> some View {
        HStack(spacing: 1) {
            Image(systemName: "v.square.fill")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(selectedVelog ? Color.green : Color.secondary)
                .frame(width: 22, height: 16)
                .background(
                    selectedVelog ? Color.green.opacity(0.25) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 3, style: .continuous)
                )
            Image(systemName: "t.square.fill")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(selectedVelog ? Color.secondary : Color.orange)
                .frame(width: 22, height: 16)
                .background(
                    selectedVelog ? Color.clear : Color.orange.opacity(0.25),
                    in: RoundedRectangle(cornerRadius: 3, style: .continuous)
                )
        }
        .padding(2)
        .background(Color.primary.opacity(0.12), in: Capsule())
    }
    
    private func largeRelatedPreviewRow(rank: Int, title: String, digest: String, date: String) -> some View {
        HStack(spacing: 5) {
            Text("\(rank)")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.green)
                .frame(width: 9, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 7, weight: .semibold))
                    .lineLimit(1)
                Text(digest)
                    .font(.system(size: 6))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            Text(date)
                .font(.system(size: 6))
                .foregroundStyle(.secondary)
        }
    }
    
    private func largeNavGradientButton(title: String, symbol: String, isLeading: Bool) -> some View {
        HStack(spacing: 3) {
            if isLeading { Image(systemName: symbol).font(.system(size: 7, weight: .semibold)) }
            Text(title).font(.system(size: 8, weight: .semibold))
            if !isLeading { Image(systemName: symbol).font(.system(size: 7, weight: .semibold)) }
        }
        .foregroundStyle(.white.opacity(0.95))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.95), Color.green.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }
}

#Preview {
    TutorialView()
}
