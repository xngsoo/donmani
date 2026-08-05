import Testing

@testable import UI

struct DMFormatterTests {
    @Test(
        "축약 표기는 만 단위부터 줄인다",
        arguments: [
            (0, "0"),
            (900, "900"),
            (9_999, "9,999"),
            (10_000, "1만"),
            (12_000, "1.2만"),
            (12_500, "1.3만"),
            (1_250_000, "125만"),
            (100_000_000, "1억"),
            (123_000_000, "1.2억"),
        ]
    )
    func compactWon(amount: Int, expected: String) {
        #expect(DMFormatter.compactWon(amount) == expected)
    }

    @Test("음수도 축약된다")
    func compactWonHandlesNegatives() {
        #expect(DMFormatter.compactWon(-12_000) == "-1.2만")
    }

    @Test("비율은 총액이 0이면 0%다")
    func percentGuardsZeroTotal() {
        #expect(DMFormatter.percent(1_000, of: 0) == "0%")
    }

    @Test("비율은 정수로 반올림된다")
    func percentRounds() {
        #expect(DMFormatter.percent(1, of: 3) == 0.333.formatted(.percent.precision(.fractionLength(0))))
        #expect(DMFormatter.percent(1, of: 4) == 0.25.formatted(.percent.precision(.fractionLength(0))))
    }
}
