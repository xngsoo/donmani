import Core
import SwiftUI
import UI

/// 카테고리별 색은 선언 순서에 고정한다. 목록이 줄어도 남은 카테고리의 색이 바뀌지 않아야 한다.
enum CategoryStyle {
    static func color(for category: RecordCategory) -> Color {
        DMColor.chartColor(slot: slot(for: category))
    }

    static func slot(for category: RecordCategory) -> Int {
        RecordCategory.allCases.firstIndex(of: category) ?? 0
    }

    static func symbol(for category: RecordCategory) -> String {
        switch category {
        case .food: "fork.knife"
        case .transport: "bus"
        case .living: "house"
        case .culture: "ticket"
        case .saving: "banknote"
        case .etc: "ellipsis.circle"
        }
    }
}
