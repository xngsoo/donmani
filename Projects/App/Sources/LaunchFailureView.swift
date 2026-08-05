import SwiftUI
import UI

struct LaunchFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: DMSpacing.l) {
            DMEmptyStateView(
                title: "실행할 수 없어요",
                message: message,
                systemImage: "exclamationmark.triangle"
            )
            DMPrimaryButton("다시 시도", action: retry)
                .padding(.horizontal, DMSpacing.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DMColor.background)
    }
}

#Preview {
    LaunchFailureView(message: "데이터를 불러오지 못했어요.\n앱을 다시 실행해 주세요.") {}
}
