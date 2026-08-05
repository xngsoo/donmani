import Core
import Foundation
import SwiftData

@MainActor
@Observable
public final class HomeViewModel {
    public enum State: Equatable {
        case loading
        case empty
        case loaded(summary: SpendingSummary, records: [RecordItem])
        case failed(message: String)
    }

    public struct RecordItem: Identifiable, Equatable {
        public let id: PersistentIdentifier
        public let amount: Int
        public let category: RecordCategory
        public let memo: String
        public let spentAt: Date

        public init(record: MoneyRecord) {
            id = record.persistentModelID
            amount = record.amount
            category = record.category
            memo = record.memo
            spentAt = record.spentAt
        }
    }

    public private(set) var state: State = .loading

    private let repository: any RecordRepository

    public init(repository: any RecordRepository) {
        self.repository = repository
    }

    public func load() {
        state = .loading
        do {
            let records = try repository.fetchAll()
            guard !records.isEmpty else {
                state = .empty
                return
            }
            let summary = SpendingSummary.make(from: records.map { ($0.category, $0.amount) })
            state = .loaded(summary: summary, records: records.map(RecordItem.init(record:)))
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    public func addSample(amount: Int, category: RecordCategory, memo: String) {
        do {
            try repository.add(amount: amount, category: category, memo: memo, spentAt: .now)
            load()
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    private static func message(for error: any Error) -> String {
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
