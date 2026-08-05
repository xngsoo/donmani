import Testing

@testable import Core

struct SpendingSummaryTests {
    @Test("입력이 없으면 빈 요약이다")
    func emptyInput() {
        #expect(SpendingSummary.make(from: []) == .empty)
    }

    @Test("같은 카테고리 금액은 합산된다")
    func aggregatesSameCategory() {
        let summary = SpendingSummary.make(from: [
            (.food, 3_000),
            (.food, 7_000),
            (.transport, 1_250),
        ])

        #expect(summary.total == 11_250)
        #expect(summary.byCategory == [
            CategoryAmount(category: .food, amount: 10_000),
            CategoryAmount(category: .transport, amount: 1_250),
        ])
    }

    @Test("금액이 동률이면 카테고리 선언 순서를 따른다")
    func breaksTiesByDeclarationOrder() {
        let summary = SpendingSummary.make(from: [
            (.culture, 5_000),
            (.food, 5_000),
        ])

        #expect(summary.byCategory.map(\.category) == [.food, .culture])
    }
}
