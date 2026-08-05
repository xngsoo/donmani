import Foundation
import SwiftData

public enum RecordRepositoryError: Error, Equatable {
    case invalidAmount(Int)
    case persistenceFailed(String)
}

/// `MoneyRecord`는 `Sendable`이 아니므로 리포지토리는 MainActor에 고정해 모델 객체가 액터 경계를 넘지 않게 한다.
@MainActor
public protocol RecordRepository: AnyObject {
    func fetchAll() throws -> [MoneyRecord]
    func fetch(in dateInterval: DateInterval) throws -> [MoneyRecord]
    @discardableResult
    func add(amount: Int, category: RecordCategory, memo: String, spentAt: Date) throws -> MoneyRecord
    func delete(_ record: MoneyRecord) throws
}

@MainActor
public final class SwiftDataRecordRepository: RecordRepository {
    /// `ModelContext`는 컨테이너를 강하게 잡지 않는다. 컨테이너를 함께 보관해 수명을 보장한다.
    private let container: ModelContainer
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.container = container
        context = container.mainContext
    }

    public func fetchAll() throws -> [MoneyRecord] {
        let descriptor = FetchDescriptor<MoneyRecord>(
            sortBy: [SortDescriptor(\.spentAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RecordRepositoryError.persistenceFailed(error.localizedDescription)
        }
    }

    public func fetch(in dateInterval: DateInterval) throws -> [MoneyRecord] {
        let start = dateInterval.start
        let end = dateInterval.end
        let descriptor = FetchDescriptor<MoneyRecord>(
            predicate: #Predicate { $0.spentAt >= start && $0.spentAt < end },
            sortBy: [SortDescriptor(\.spentAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            throw RecordRepositoryError.persistenceFailed(error.localizedDescription)
        }
    }

    @discardableResult
    public func add(
        amount: Int,
        category: RecordCategory,
        memo: String = "",
        spentAt: Date = .now
    ) throws -> MoneyRecord {
        guard amount > 0 else { throw RecordRepositoryError.invalidAmount(amount) }

        let record = MoneyRecord(amount: amount, category: category, memo: memo, spentAt: spentAt)
        context.insert(record)
        try save()
        return record
    }

    public func delete(_ record: MoneyRecord) throws {
        context.delete(record)
        try save()
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            throw RecordRepositoryError.persistenceFailed(error.localizedDescription)
        }
    }
}
