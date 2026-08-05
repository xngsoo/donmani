import Foundation

public enum SpendingAggregator {
    /// 자정 기준으로 묶은 날짜별 합계. 달력 셀이 O(1)로 조회한다.
    public static func dailyTotals(
        of entries: [(date: Date, amount: Int)],
        calendar: Calendar = .current
    ) -> [Date: Int] {
        entries.reduce(into: [:]) { totals, entry in
            totals[calendar.startOfDay(for: entry.date), default: 0] += entry.amount
        }
    }
}
