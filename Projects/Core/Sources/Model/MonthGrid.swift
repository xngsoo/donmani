import Foundation

/// 달력 화면이 그대로 그릴 수 있는 한 달치 주 단위 격자. 날짜 계산을 View 밖에 두어 단위 테스트한다.
public struct MonthGrid: Equatable, Sendable {
    public struct Day: Equatable, Sendable, Identifiable {
        public let date: Date
        public let number: Int
        public let isWithinMonth: Bool

        public var id: Date { date }
    }

    public let monthStart: Date
    public let interval: DateInterval
    public let weeks: [[Day]]

    public var days: [Day] { weeks.flatMap(\.self) }

    public static func make(containing date: Date, calendar: Calendar = .current) -> MonthGrid? {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: monthInterval.start)?.count
        else { return nil }

        let monthStart = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let cellCount = Int((Double(leading + dayCount) / 7).rounded(.up)) * 7

        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) else { return nil }

        var days: [Day] = []
        days.reserveCapacity(cellCount)
        for offset in 0 ..< cellCount {
            guard let raw = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let start = calendar.startOfDay(for: raw)
            days.append(
                Day(
                    date: start,
                    number: calendar.component(.day, from: start),
                    isWithinMonth: calendar.isDate(start, equalTo: monthStart, toGranularity: .month)
                )
            )
        }

        return MonthGrid(
            monthStart: monthStart,
            interval: monthInterval,
            weeks: stride(from: 0, to: days.count, by: 7).map { Array(days[$0 ..< $0 + 7]) }
        )
    }

    /// 월 이동. 이동 결과가 유효하지 않으면 nil을 돌려 호출자가 현재 격자를 유지하게 한다.
    public func advanced(byMonths value: Int, calendar: Calendar = .current) -> MonthGrid? {
        guard let moved = calendar.date(byAdding: .month, value: value, to: monthStart) else { return nil }
        return MonthGrid.make(containing: moved, calendar: calendar)
    }
}
