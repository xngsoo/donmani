import Core
import Foundation
import SwiftData

/// 프리뷰 전용 조립기. 인메모리 컨테이너를 쓰고, 실패하면 에러 상태를 보여주는 리포지토리로 대체한다.
@MainActor
enum PreviewFactory {
    static func repository(seeded: Bool) -> any RecordRepository {
        do {
            let repository = SwiftDataRecordRepository(container: try ModelContainerFactory.make(inMemory: true))
            guard seeded else { return repository }

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let samples: [(offset: Int, hour: Int, amount: Int, category: RecordCategory, memo: String)] = [
                (0, 8, 4_500, .food, "아침"),
                (0, 12, 13_000, .food, "점심"),
                (0, 13, 2_800, .transport, "지하철"),
                (0, 20, 30_000, .culture, "공연"),
                (-1, 19, 62_000, .living, "생필품"),
                (-3, 9, 150_000, .saving, "적금"),
                (-6, 21, 8_900, .etc, "기타"),
            ]
            for sample in samples {
                guard let day = calendar.date(byAdding: .day, value: sample.offset, to: today),
                      let at = calendar.date(bySettingHour: sample.hour, minute: 0, second: 0, of: day)
                else { continue }
                try repository.add(
                    amount: sample.amount,
                    category: sample.category,
                    memo: sample.memo,
                    spentAt: at
                )
            }
            return repository
        } catch {
            return FailingPreviewRepository()
        }
    }

    static func homeViewModel(seeded: Bool) -> HomeViewModel {
        HomeViewModel(repository: repository(seeded: seeded))
    }
}

@MainActor
final class FailingPreviewRepository: RecordRepository {
    private func fail() -> RecordRepositoryError { .persistenceFailed("preview") }

    func fetchAll() throws -> [MoneyRecord] { throw fail() }
    func fetch(in dateInterval: DateInterval) throws -> [MoneyRecord] { throw fail() }
    func record(with id: PersistentIdentifier) throws -> MoneyRecord? { throw fail() }
    func add(amount: Int, category: RecordCategory, memo: String, spentAt: Date) throws -> MoneyRecord {
        throw fail()
    }

    func update(
        _ record: MoneyRecord,
        amount: Int,
        category: RecordCategory,
        memo: String,
        spentAt: Date
    ) throws {
        throw fail()
    }

    func delete(_ record: MoneyRecord) throws { throw fail() }
}
