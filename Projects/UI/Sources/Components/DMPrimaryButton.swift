import SwiftUI

public struct DMPrimaryButton: View {
    private let title: String
    private let systemImage: String?
    private let isEnabled: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DMSpacing.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(DMFont.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DMSpacing.m)
            .background(DMColor.accent, in: .rect(cornerRadius: DMRadius.button))
            .foregroundStyle(.white)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

#Preview("기본") {
    VStack(spacing: DMSpacing.m) {
        DMPrimaryButton("기록 추가", systemImage: "plus") {}
        DMPrimaryButton("비활성", isEnabled: false) {}
    }
    .padding()
}
