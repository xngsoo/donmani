import Foundation
import Testing

@testable import Core

private let seoul = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
    calendar.firstWeekday = 1
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    seoul.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
}

struct MonthGridTests {
    @Test("격자는 항상 7일 단위 주로 채워진다")
    func gridIsFilledInFullWeeks() throws {
        let grid = try #require(MonthGrid.make(containing: date(2026, 8, 5), calendar: seoul))

        #expect(grid.weeks.allSatisfy { $0.count == 7 })
        #expect(grid.days.count % 7 == 0)
    }

    @Test("2026년 8월은 토요일에 시작하므로 앞에 6칸이 채워진다")
    func leadingDaysComeFromPreviousMonth() throws {
        let grid = try #require(MonthGrid.make(containing: date(2026, 8, 5), calendar: seoul))
        let leading = grid.days.prefix { !$0.isWithinMonth }

        #expect(leading.count == 6)
        #expect(leading.map(\.number) == [26, 27, 28, 29, 30, 31])
        #expect(grid.days.filter(\.isWithinMonth).count == 31)
    }

    @Test("첫 요일 설정을 월요일로 바꾸면 선행 칸 수가 달라진다")
    func respectsFirstWeekday() throws {
        var mondayFirst = seoul
        mondayFirst.firstWeekday = 2
        let grid = try #require(MonthGrid.make(containing: date(2026, 8, 5), calendar: mondayFirst))

        #expect(grid.days.prefix { !$0.isWithinMonth }.count == 5)
    }

    @Test("월의 시작과 구간이 정확하다")
    func monthStartAndInterval() throws {
        let grid = try #require(MonthGrid.make(containing: date(2026, 8, 5), calendar: seoul))

        #expect(grid.monthStart == seoul.startOfDay(for: date(2026, 8, 1)))
        #expect(grid.interval.end == seoul.startOfDay(for: date(2026, 9, 1)))
    }

    @Test("모든 셀은 자정으로 정규화된다")
    func daysAreNormalizedToMidnight() throws {
        let grid = try #require(MonthGrid.make(containing: date(2026, 8, 5), calendar: seoul))

        #expect(grid.days.allSatisfy { $0.date == seoul.startOfDay(for: $0.date) })
    }

    @Test("월 이동은 연도 경계를 넘는다", arguments: [(1, 2027, 1), (-1, 2026, 11), (12, 2027, 12)])
    func advancingCrossesYearBoundary(offset: Int, expectedYear: Int, expectedMonth: Int) throws {
        let december = try #require(MonthGrid.make(containing: date(2026, 12, 15), calendar: seoul))

        let moved = try #require(december.advanced(byMonths: offset, calendar: seoul))

        #expect(seoul.component(.year, from: moved.monthStart) == expectedYear)
        #expect(seoul.component(.month, from: moved.monthStart) == expectedMonth)
    }
}

struct SpendingAggregatorTests {
    @Test("같은 날 기록은 자정 기준으로 합산된다")
    func aggregatesByDay() {
        let totals = SpendingAggregator.dailyTotals(
            of: [
                (date(2026, 8, 5), 10_000),
                (seoul.date(bySettingHour: 23, minute: 59, second: 0, of: date(2026, 8, 5)) ?? .now, 5_000),
                (date(2026, 8, 6), 3_000),
            ],
            calendar: seoul
        )

        #expect(totals[seoul.startOfDay(for: date(2026, 8, 5))] == 15_000)
        #expect(totals[seoul.startOfDay(for: date(2026, 8, 6))] == 3_000)
        #expect(totals.count == 2)
    }

    @Test("빈 입력은 빈 사전이다")
    func emptyInput() {
        #expect(SpendingAggregator.dailyTotals(of: [], calendar: seoul).isEmpty)
    }
}
