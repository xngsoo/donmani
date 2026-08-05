import Foundation
import SwiftData
import Testing

@testable import Core

@MainActor
struct RecordRepositoryTests {
    private func makeRepository() throws -> SwiftDataRecordRepository {
        let container = try ModelContainerFactory.make(inMemory: true)
        return SwiftDataRecordRepository(container: container)
    }

    @Test("추가한 기록을 다시 조회할 수 있다")
    func addThenFetch() throws {
        let repository = try makeRepository()

        try repository.add(amount: 12_000, category: .food, memo: "점심", spentAt: .now)

        let records = try repository.fetchAll()
        #expect(records.count == 1)
        #expect(records.first?.amount == 12_000)
        #expect(records.first?.category == .food)
    }

    @Test("0 이하 금액은 저장되지 않는다", arguments: [0, -1, -10_000])
    func rejectsNonPositiveAmount(amount: Int) throws {
        let repository = try makeRepository()

        #expect(throws: RecordRepositoryError.invalidAmount(amount)) {
            try repository.add(amount: amount, category: .etc, memo: "", spentAt: .now)
        }
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test("조회 결과는 최신순으로 정렬된다")
    func fetchAllIsSortedByRecency() throws {
        let repository = try makeRepository()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        try repository.add(amount: 1_000, category: .food, memo: "이틀 전", spentAt: now.addingTimeInterval(-172_800))
        try repository.add(amount: 2_000, category: .transport, memo: "오늘", spentAt: now)
        try repository.add(amount: 3_000, category: .culture, memo: "어제", spentAt: now.addingTimeInterval(-86_400))

        let memos = try repository.fetchAll().map(\.memo)
        #expect(memos == ["오늘", "어제", "이틀 전"])
    }

    @Test("기간 조회는 시작일 포함, 종료일 미포함이다")
    func fetchInIntervalIsHalfOpen() throws {
        let repository = try makeRepository()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(3_600)

        try repository.add(amount: 100, category: .etc, memo: "경계-시작", spentAt: start)
        try repository.add(amount: 200, category: .etc, memo: "경계-끝", spentAt: end)
        try repository.add(amount: 300, category: .etc, memo: "이전", spentAt: start.addingTimeInterval(-1))

        let records = try repository.fetch(in: DateInterval(start: start, end: end))
        #expect(records.map(\.memo) == ["경계-시작"])
    }

    @Test("삭제한 기록은 조회되지 않는다")
    func deleteRemovesRecord() throws {
        let repository = try makeRepository()
        let record = try repository.add(amount: 5_000, category: .saving, memo: "적금", spentAt: .now)

        try repository.delete(record)

        #expect(try repository.fetchAll().isEmpty)
    }
}
