import Core
import Foundation
import SwiftData

@MainActor
@Observable
public final class DayDetailViewModel {
    public struct RecordItem: Identifiable, Equatable {
        public let id: PersistentIdentifier
        public let amount: Int
        public let category: RecordCategory
        public let memo: String
        public let spentAt: Date

        init(record: MoneyRecord) {
            id = record.persistentModelID
            amount = record.amount
            category = record.category
            memo = record.memo
            spentAt = record.spentAt
        }
    }

    public enum State: Equatable {
        case loading
        case empty
        case loaded(summary: SpendingSummary, records: [RecordItem])
        case failed(message: String)
    }

    public private(set) var state: State = .loading
    public let date: Date

    private let repository: any RecordRepository
    private let calendar: Calendar

    init(repository: any RecordRepository, date: Date, calendar: Calendar) {
        self.repository = repository
        self.date = calendar.startOfDay(for: date)
        self.calendar = calendar
    }

    public var title: String {
        date.formatted(.dateTime.locale(.current).month(.wide).day().weekday(.wide))
    }

    public func load() {
        guard let end = calendar.date(byAdding: .day, value: 1, to: date) else {
            state = .failed(message: "날짜 범위를 계산하지 못했어요.")
            return
        }

        do {
            let records = try repository.fetch(in: DateInterval(start: date, end: end))
                .sorted { $0.spentAt < $1.spentAt }
            guard !records.isEmpty else {
                state = .empty
                return
            }
            state = .loaded(
                summary: SpendingSummary.make(from: records.map { ($0.category, $0.amount) }),
                records: records.map(RecordItem.init(record:))
            )
        } catch {
            state = .failed(message: ErrorMessage.text(for: error))
        }
    }

    public func delete(_ item: RecordItem) {
        do {
            guard let record = try repository.record(with: item.id) else { return }
            try repository.delete(record)
            load()
        } catch {
            state = .failed(message: ErrorMessage.text(for: error))
        }
    }

    public func makeEditorViewModel(for item: RecordItem?) -> RecordEditViewModel {
        RecordEditViewModel(repository: repository, mode: item.map { .edit($0.id) } ?? .create(on: date))
    }
}
