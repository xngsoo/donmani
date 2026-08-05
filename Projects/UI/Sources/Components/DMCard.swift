import SwiftUI

public struct DMCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(DMSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DMColor.surface, in: .rect(cornerRadius: DMRadius.card))
    }
}

public struct DMEmptyStateView: View {
    private let title: String
    private let message: String
    private let systemImage: String

    public init(title: String, message: String, systemImage: String = "tray") {
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .font(DMFont.headline)
        } description: {
            Text(message)
                .font(DMFont.body)
        }
    }
}

#Preview("카드") {
    DMCard {
        VStack(alignment: .leading, spacing: DMSpacing.xs) {
            Text("이번 달 지출").font(DMFont.caption).foregroundStyle(DMColor.secondaryText)
            Text(DMFormatter.won(1_234_500)).font(DMFont.amount)
        }
    }
    .padding()
    .background(DMColor.background)
}

#Preview("빈 상태") {
    DMEmptyStateView(title: "기록이 없어요", message: "첫 지출을 기록해 보세요.")
}
