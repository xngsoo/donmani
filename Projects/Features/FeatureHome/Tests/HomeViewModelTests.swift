import Core
import Foundation
import Testing

@testable import FeatureHome

@MainActor
private final class StubRecordRepository: RecordRepository {
    var error: (any Error)?

    func fetchAll() throws -> [MoneyRecord] {
        if let error { throw error }
        return []
    }

    func fetch(in dateInterval: DateInterval) throws -> [MoneyRecord] {
        try fetchAll()
    }

    func add(amount: Int, category: RecordCategory, memo: String, spentAt: Date) throws -> MoneyRecord {
        if let error { throw error }
        return MoneyRecord(amount: amount, category: category, memo: memo, spentAt: spentAt)
    }

    func delete(_ record: MoneyRecord) throws {
        if let error { throw error }
    }
}

@MainActor
struct HomeViewModelTests {
    private func makeViewModel() throws -> HomeViewModel {
        let repository = SwiftDataRecordRepository(container: try ModelContainerFactory.make(inMemory: true))
        return HomeViewModel(repository: repository)
    }

    private func makeViewModel(with repository: some RecordRepository) -> HomeViewModel {
        HomeViewModel(repository: repository)
    }

    @Test("기록이 없으면 empty 상태다")
    func loadWithoutRecords() throws {
        let viewModel = try makeViewModel()

        viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("기록이 있으면 합계가 계산된 loaded 상태다")
    func loadWithRecords() throws {
        let repository = SwiftDataRecordRepository(container: try ModelContainerFactory.make(inMemory: true))
        try repository.add(amount: 10_000, category: .food, memo: "점심", spentAt: .now)
        try repository.add(amount: 5_000, category: .food, memo: "커피", spentAt: .now)
        try repository.add(amount: 2_000, category: .transport, memo: "버스", spentAt: .now)
        let viewModel = HomeViewModel(repository: repository)

        viewModel.load()

        guard case let .loaded(summary, records) = viewModel.state else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }
        #expect(summary.total == 17_000)
        #expect(summary.byCategory.first == CategoryAmount(category: .food, amount: 15_000))
        #expect(records.count == 3)
    }

    @Test("조회 실패는 사용자용 메시지가 담긴 failed 상태가 된다")
    func loadFailure() {
        let repository = StubRecordRepository()
        repository.error = RecordRepositoryError.persistenceFailed("boom")
        let viewModel = makeViewModel(with: repository)

        viewModel.load()

        #expect(viewModel.state == .failed(message: "저장소를 읽는 데 실패했어요. 잠시 후 다시 시도해 주세요."))
    }

    @Test("잘못된 금액 추가는 금액 안내 메시지를 보여준다")
    func addInvalidAmount() throws {
        let viewModel = try makeViewModel()

        viewModel.addSample(amount: 0, category: .etc, memo: "")

        #expect(viewModel.state == .failed(message: "금액은 1원 이상이어야 해요."))
    }

    @Test("추가에 성공하면 목록이 갱신된다")
    func addRefreshesList() throws {
        let viewModel = try makeViewModel()
        viewModel.load()
        #expect(viewModel.state == .empty)

        viewModel.addSample(amount: 3_000, category: .living, memo: "생필품")

        guard case let .loaded(summary, records) = viewModel.state else {
            Issue.record("loaded 상태를 기대했지만 \(viewModel.state)")
            return
        }
        #expect(summary.total == 3_000)
        #expect(records.count == 1)
    }
}
