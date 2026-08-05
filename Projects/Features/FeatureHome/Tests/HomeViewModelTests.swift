import Core
import Foundation
import SwiftData
import Testing

@testable import FeatureHome

@MainActor
private final class StubRecordRepository: RecordRepository {
    var error: (any Error)?

    func fetchAll() throws -> [MoneyRecord] {
        if let error { throw error }
        return []
    }

    func fetch(in dateInterval: DateInterval) throws -> [MoneyRecord] { try fetchAll() }
    func record(with id: PersistentIdentifier) throws -> MoneyRecord? {
        if let error { throw error }
        return nil
    }

    func add(amount: Int, category: RecordCategory, memo: String, spentAt: Date) throws -> MoneyRecord {
        if let error { throw error }
        return MoneyRecord(amount: amount, category: category, memo: memo, spentAt: spentAt)
    }

    func update(
        _ record: MoneyRecord,
        amount: Int,
        category: RecordCategory,
        memo: String,
        spentAt: Date
    ) throws {
        if let error { throw error }
    }

    func delete(_ record: MoneyRecord) throws {
        if let error { throw error }
    }
}

@MainActor
private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
    calendar.firstWeekday = 1
    return calendar
}

@MainActor
private func makeRepository() throws -> SwiftDataRecordRepository {
    SwiftDataRecordRepository(container: try ModelContainerFactory.make(inMemory: true))
}

private func date(_ calendar: Calendar, _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
}

@MainActor
struct HomeViewModelTests {
    @Test("해당 월의 날짜별 합계와 월 합계를 계산한다")
    func loadsMonthlyTotals() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        try repository.add(amount: 10_000, category: .food, memo: "", spentAt: date(calendar, 2026, 8, 5, 9))
        try repository.add(amount: 5_000, category: .food, memo: "", spentAt: date(calendar, 2026, 8, 5, 20))
        try repository.add(amount: 3_000, category: .transport, memo: "", spentAt: date(calendar, 2026, 8, 7))
        let viewModel = HomeViewModel(
            repository: repository,
            calendar: calendar,
            today: date(calendar, 2026, 8, 15)
        )

        viewModel.load()

        guard case let .loaded(month) = viewModel.state else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }
        #expect(month.total == 18_000)
        #expect(month.recordCount == 3)
        #expect(viewModel.amount(on: date(calendar, 2026, 8, 5)) == 15_000)
        #expect(viewModel.amount(on: date(calendar, 2026, 8, 7)) == 3_000)
        #expect(viewModel.amount(on: date(calendar, 2026, 8, 6)) == nil)
    }

    @Test("다른 달 기록은 합계에 들어가지 않는다")
    func excludesOtherMonths() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        try repository.add(amount: 99_000, category: .etc, memo: "", spentAt: date(calendar, 2026, 7, 31, 23))
        try repository.add(amount: 1_000, category: .etc, memo: "", spentAt: date(calendar, 2026, 8, 1, 0))
        try repository.add(amount: 88_000, category: .etc, memo: "", spentAt: date(calendar, 2026, 9, 1, 0))
        let viewModel = HomeViewModel(
            repository: repository,
            calendar: calendar,
            today: date(calendar, 2026, 8, 15)
        )

        viewModel.load()

        guard case let .loaded(month) = viewModel.state else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }
        #expect(month.total == 1_000)
    }

    @Test("월 이동 후 그 달의 합계로 갱신된다")
    func moveMonthReloads() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        try repository.add(amount: 7_000, category: .food, memo: "", spentAt: date(calendar, 2026, 7, 10))
        let viewModel = HomeViewModel(
            repository: repository,
            calendar: calendar,
            today: date(calendar, 2026, 8, 15)
        )
        viewModel.load()
        #expect(viewModel.amount(on: date(calendar, 2026, 7, 10)) == nil)

        viewModel.moveMonth(by: -1)

        guard case let .loaded(month) = viewModel.state else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }
        #expect(month.total == 7_000)
        #expect(calendar.component(.month, from: month.grid.monthStart) == 7)
    }

    @Test("요일 머리글은 첫 요일 설정을 따른다")
    func weekdaySymbolsFollowFirstWeekday() throws {
        var mondayFirst = makeCalendar()
        mondayFirst.firstWeekday = 2
        let viewModel = HomeViewModel(repository: try makeRepository(), calendar: mondayFirst)

        #expect(viewModel.weekdaySymbols.first == mondayFirst.shortWeekdaySymbols[1])
        #expect(viewModel.weekdaySymbols.count == 7)
    }

    @Test("날짜 선택은 자정으로 정규화된다")
    func selectionNormalizesToMidnight() throws {
        let calendar = makeCalendar()
        let viewModel = HomeViewModel(repository: try makeRepository(), calendar: calendar)

        viewModel.select(date(calendar, 2026, 8, 5, 17))

        #expect(viewModel.selectedDay?.date == calendar.startOfDay(for: date(calendar, 2026, 8, 5)))
    }

    @Test("조회 실패는 사용자용 메시지가 담긴 failed 상태가 된다")
    func loadFailure() {
        let repository = StubRecordRepository()
        repository.error = RecordRepositoryError.persistenceFailed("boom")
        let viewModel = HomeViewModel(repository: repository, calendar: makeCalendar())

        viewModel.load()

        #expect(viewModel.state == .failed(message: "저장소를 읽는 데 실패했어요. 잠시 후 다시 시도해 주세요."))
    }
}

@MainActor
struct DayDetailViewModelTests {
    @Test("그 날 기록만 시간순으로 모으고 카테고리별로 합산한다")
    func loadsDayRecords() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        try repository.add(amount: 3_000, category: .food, memo: "저녁", spentAt: date(calendar, 2026, 8, 5, 19))
        try repository.add(amount: 9_000, category: .food, memo: "점심", spentAt: date(calendar, 2026, 8, 5, 12))
        try repository.add(amount: 2_000, category: .transport, memo: "버스", spentAt: date(calendar, 2026, 8, 5, 8))
        try repository.add(amount: 50_000, category: .etc, memo: "다음날", spentAt: date(calendar, 2026, 8, 6, 1))
        let viewModel = DayDetailViewModel(
            repository: repository,
            date: date(calendar, 2026, 8, 5, 23),
            calendar: calendar
        )

        viewModel.load()

        guard case let .loaded(summary, records) = viewModel.state else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }
        #expect(summary.total == 14_000)
        #expect(summary.byCategory.first == CategoryAmount(category: .food, amount: 12_000))
        #expect(records.map(\.memo) == ["버스", "점심", "저녁"])
    }

    @Test("기록이 없는 날은 empty 상태다")
    func emptyDay() throws {
        let calendar = makeCalendar()
        let viewModel = DayDetailViewModel(
            repository: try makeRepository(),
            date: date(calendar, 2026, 8, 5),
            calendar: calendar
        )

        viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("삭제하면 목록에서 사라진다")
    func deleteRemovesRecord() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        try repository.add(amount: 3_000, category: .food, memo: "저녁", spentAt: date(calendar, 2026, 8, 5, 19))
        let viewModel = DayDetailViewModel(
            repository: repository,
            date: date(calendar, 2026, 8, 5),
            calendar: calendar
        )
        viewModel.load()
        guard case let .loaded(_, records) = viewModel.state, let first = records.first else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }

        viewModel.delete(first)

        #expect(viewModel.state == .empty)
    }
}

@MainActor
struct RecordEditViewModelTests {
    @Test("추가 모드로 저장하면 기록이 생긴다")
    func createSavesRecord() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        let day = date(calendar, 2026, 8, 5)
        let viewModel = RecordEditViewModel(repository: repository, mode: .create(on: day))
        viewModel.amountText = "12000"
        viewModel.category = .culture
        viewModel.memo = "  영화  "
        viewModel.spentAt = date(calendar, 2026, 8, 5, 20)

        #expect(viewModel.save())

        let stored = try #require(try repository.fetchAll().first)
        #expect(stored.amount == 12_000)
        #expect(stored.category == .culture)
        #expect(stored.memo == "영화")
    }

    @Test("수정 모드는 기존 값을 채우고 저장 시 갱신한다")
    func editUpdatesRecord() throws {
        let calendar = makeCalendar()
        let repository = try makeRepository()
        let record = try repository.add(
            amount: 5_000,
            category: .food,
            memo: "점심",
            spentAt: date(calendar, 2026, 8, 5, 12)
        )
        let viewModel = RecordEditViewModel(repository: repository, mode: .edit(record.persistentModelID))
        #expect(viewModel.amountText == "5000")
        #expect(viewModel.category == .food)
        #expect(viewModel.memo == "점심")

        viewModel.amountText = "8,500"
        viewModel.category = .living

        #expect(viewModel.save())
        let stored = try #require(try repository.fetchAll().first)
        #expect(stored.amount == 8_500)
        #expect(stored.category == .living)
    }

    @Test("금액이 비었거나 0이면 저장할 수 없다", arguments: ["", "0", "abc"])
    func rejectsInvalidAmount(text: String) throws {
        let repository = try makeRepository()
        let viewModel = RecordEditViewModel(repository: repository, mode: .create(on: .now))
        viewModel.amountText = text

        #expect(!viewModel.canSave)
        #expect(!viewModel.save())
        #expect(viewModel.errorMessage == "금액은 1원 이상이어야 해요.")
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test("수정 모드에서 삭제하면 기록이 사라진다")
    func deleteRemovesRecord() throws {
        let repository = try makeRepository()
        let record = try repository.add(amount: 1_000, category: .etc, memo: "", spentAt: .now)
        let viewModel = RecordEditViewModel(repository: repository, mode: .edit(record.persistentModelID))

        #expect(viewModel.delete())
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test("추가 모드에서는 삭제가 동작하지 않는다")
    func deleteIsNoOpWhenCreating() throws {
        let viewModel = RecordEditViewModel(repository: try makeRepository(), mode: .create(on: .now))

        #expect(!viewModel.delete())
    }
}
