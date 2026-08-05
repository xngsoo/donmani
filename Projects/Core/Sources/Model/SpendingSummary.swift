import Foundation

public struct CategoryAmount: Equatable, Sendable, Identifiable {
    public let category: RecordCategory
    public let amount: Int

    public var id: RecordCategory { category }

    public init(category: RecordCategory, amount: Int) {
        self.category = category
        self.amount = amount
    }
}

public struct SpendingSummary: Equatable, Sendable {
    public let total: Int
    public let byCategory: [CategoryAmount]

    public static let empty = SpendingSummary(total: 0, byCategory: [])

    public init(total: Int, byCategory: [CategoryAmount]) {
        self.total = total
        self.byCategory = byCategory
    }

    /// 금액이 큰 카테고리부터 정렬한다. 동률이면 카테고리 선언 순서를 따른다.
    public static func make(from amounts: [(category: RecordCategory, amount: Int)]) -> SpendingSummary {
        guard !amounts.isEmpty else { return .empty }

        var totals: [RecordCategory: Int] = [:]
        for entry in amounts {
            totals[entry.category, default: 0] += entry.amount
        }

        let ordering = Dictionary(
            uniqueKeysWithValues: RecordCategory.allCases.enumerated().map { ($0.element, $0.offset) }
        )
        let byCategory = totals
            .map { CategoryAmount(category: $0.key, amount: $0.value) }
            .sorted {
                $0.amount == $1.amount
                    ? ordering[$0.category, default: 0] < ordering[$1.category, default: 0]
                    : $0.amount > $1.amount
            }

        return SpendingSummary(total: totals.values.reduce(0, +), byCategory: byCategory)
    }
}
