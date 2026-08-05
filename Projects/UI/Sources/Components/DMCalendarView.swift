import SwiftUI

/// 도메인을 모르는 순수 표현 컴포넌트. 날짜 계산과 금액 집계는 호출자가 끝내서 넘긴다.
public struct DMCalendarView: View {
    public struct DayItem: Identifiable, Equatable {
        public let date: Date
        public let number: Int
        public let isWithinMonth: Bool
        public let isToday: Bool
        public let amount: Int?

        public var id: Date { date }

        public init(date: Date, number: Int, isWithinMonth: Bool, isToday: Bool, amount: Int?) {
            self.date = date
            self.number = number
            self.isWithinMonth = isWithinMonth
            self.isToday = isToday
            self.amount = amount
        }
    }

    private let weeks: [[DayItem]]
    private let weekdaySymbols: [String]
    private let selectedDate: Date?
    private let onSelect: (Date) -> Void

    public init(
        weeks: [[DayItem]],
        weekdaySymbols: [String],
        selectedDate: Date?,
        onSelect: @escaping (Date) -> Void
    ) {
        self.weeks = weeks
        self.weekdaySymbols = weekdaySymbols
        self.selectedDate = selectedDate
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: DMSpacing.xs) {
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(DMFont.caption)
                        .foregroundStyle(DMColor.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            // 부모가 남는 세로 공간을 주면 주 단위로 고르게 나눠 갖는다.
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(week) { day in
                        cell(for: day)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func cell(for day: DayItem) -> some View {
        let isSelected = selectedDate.map { $0 == day.date } ?? false

        return Button {
            onSelect(day.date)
        } label: {
            VStack(spacing: 2) {
                Text("\(day.number)")
                    .font(DMFont.caption)
                    .foregroundStyle(numberColor(day, isSelected: isSelected))
                    .frame(width: 24, height: 24)
                    .background {
                        if day.isToday {
                            Circle().fill(isSelected ? .white.opacity(0.25) : DMColor.accent.opacity(0.18))
                        }
                    }

                Text(day.amount.map(DMFormatter.compactWon) ?? " ")
                    .font(.system(size: 10, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(amountColor(day, isSelected: isSelected))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DMSpacing.xs)
            .background(isSelected ? DMColor.accent : .clear, in: .rect(cornerRadius: DMRadius.button))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: day))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func numberColor(_ day: DayItem, isSelected: Bool) -> Color {
        if isSelected { return .white }
        return day.isWithinMonth ? DMColor.primaryText : DMColor.tertiaryText
    }

    private func amountColor(_ day: DayItem, isSelected: Bool) -> Color {
        if isSelected { return .white }
        return day.isWithinMonth ? DMColor.secondaryText : DMColor.tertiaryText
    }

    private func accessibilityLabel(for day: DayItem) -> String {
        let base = day.date.formatted(.dateTime.month(.wide).day())
        guard let amount = day.amount else { return "\(base), 지출 없음" }
        return "\(base), \(DMFormatter.won(amount))"
    }
}

#Preview("달력") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let start = calendar.date(byAdding: .day, value: -17, to: today) ?? today
    let amounts = [0: 12_000, 3: 148_000, 5: 3_200, 11: 27_500, 17: 9_000, 20: 1_250_000]
    let days = (0 ..< 35).map { offset -> DMCalendarView.DayItem in
        let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
        return DMCalendarView.DayItem(
            date: date,
            number: calendar.component(.day, from: date),
            isWithinMonth: offset >= 3 && offset < 34,
            isToday: date == today,
            amount: amounts[offset]
        )
    }

    return DMCalendarView(
        weeks: stride(from: 0, to: days.count, by: 7).map { Array(days[$0 ..< $0 + 7]) },
        weekdaySymbols: ["일", "월", "화", "수", "목", "금", "토"],
        selectedDate: today,
        onSelect: { _ in }
    )
    .padding()
    .background(DMColor.background)
}
