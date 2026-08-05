import Core
import Foundation

@MainActor
@Observable
public final class HomeViewModel {
    public struct Month: Equatable {
        public let grid: MonthGrid
        public let dailyTotals: [Date: Int]
        public let total: Int
        public let recordCount: Int
    }

    public enum State: Equatable {
        case loading
        case loaded(Month)
        case failed(message: String)
    }

    public private(set) var state: State = .loading
    public var selectedDay: SelectedDay?

    public struct SelectedDay: Identifiable, Hashable {
        public let date: Date
        public var id: Date { date }
    }

    private let repository: any RecordRepository
    private let calendar: Calendar
    private var anchor: Date

    public init(repository: any RecordRepository, calendar: Calendar = .current, today: Date = .now) {
        self.repository = repository
        self.calendar = calendar
        anchor = today
    }

    public var monthTitle: String {
        guard case let .loaded(month) = state else { return "" }
        return month.grid.monthStart.formatted(
            .dateTime.locale(.current).year().month(.wide)
        )
    }

    public var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }

    public var isEmptyMonth: Bool {
        guard case let .loaded(month) = state else { return false }
        return month.recordCount == 0
    }

    public func load() {
        guard let grid = MonthGrid.make(containing: anchor, calendar: calendar) else {
            state = .failed(message: "달력을 만들지 못했어요.")
            return
        }

        do {
            let records = try repository.fetch(in: grid.interval)
            let totals = SpendingAggregator.dailyTotals(
                of: records.map { (date: $0.spentAt, amount: $0.amount) },
                calendar: calendar
            )
            state = .loaded(
                Month(
                    grid: grid,
                    dailyTotals: totals,
                    total: records.reduce(0) { $0 + $1.amount },
                    recordCount: records.count
                )
            )
        } catch {
            state = .failed(message: ErrorMessage.text(for: error))
        }
    }

    /// 가로 스와이프를 월 이동량으로 바꾼다. 세로가 더 크거나 이동이 짧으면 무시한다.
    public nonisolated static func monthStep(
        horizontal: CGFloat,
        vertical: CGFloat,
        threshold: CGFloat
    ) -> Int? {
        guard abs(horizontal) > abs(vertical), abs(horizontal) > threshold else { return nil }
        return horizontal < 0 ? 1 : -1
    }

    public func moveMonth(by value: Int) {
        guard let moved = calendar.date(byAdding: .month, value: value, to: anchor) else { return }
        anchor = moved
        load()
    }

    public func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    public func amount(on date: Date) -> Int? {
        guard case let .loaded(month) = state else { return nil }
        return month.dailyTotals[calendar.startOfDay(for: date)]
    }

    public func select(_ date: Date) {
        selectedDay = SelectedDay(date: calendar.startOfDay(for: date))
    }

    public func selectToday() {
        select(.now)
    }

    public func makeDayViewModel(for date: Date) -> DayDetailViewModel {
        DayDetailViewModel(repository: repository, date: date, calendar: calendar)
    }
}

enum ErrorMessage {
    static func text(for error: any Error) -> String {
        guard let error = error as? RecordRepositoryError else {
            return "알 수 없는 오류가 발생했어요."
        }
        switch error {
        case .invalidAmount:
            return "금액은 1원 이상이어야 해요."
        case .persistenceFailed:
            return "저장소를 읽는 데 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}
