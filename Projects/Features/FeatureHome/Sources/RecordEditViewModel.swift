import Core
import Foundation
import SwiftData

@MainActor
@Observable
public final class RecordEditViewModel: Identifiable {
    /// 시트 표현용 식별자. 인스턴스 주소만 쓰므로 액터 밖에서 읽어도 안전하다.
    public nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }

    public enum Mode: Equatable {
        case create(on: Date)
        case edit(PersistentIdentifier)
    }

    public var amountText: String = ""
    public var category: RecordCategory = .food
    public var memo: String = ""
    public var spentAt: Date = .now
    public private(set) var errorMessage: String?

    private let repository: any RecordRepository
    private let mode: Mode

    init(repository: any RecordRepository, mode: Mode) {
        self.repository = repository
        self.mode = mode

        switch mode {
        case let .create(date):
            spentAt = Self.defaultTime(on: date)
        case let .edit(id):
            if let record = try? repository.record(with: id) {
                amountText = String(record.amount)
                category = record.category
                memo = record.memo
                spentAt = record.spentAt
            } else {
                errorMessage = "기록을 찾지 못했어요."
            }
        }
    }

    public var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    public var title: String { isEditing ? "기록 수정" : "기록 추가" }

    public var amount: Int? {
        Int(amountText.filter(\.isNumber))
    }

    public var canSave: Bool {
        (amount ?? 0) > 0
    }

    /// 저장에 성공하면 true. 호출한 View가 이 값으로 dismiss 여부를 정한다.
    public func save() -> Bool {
        guard let amount, amount > 0 else {
            errorMessage = "금액은 1원 이상이어야 해요."
            return false
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            switch mode {
            case .create:
                try repository.add(amount: amount, category: category, memo: trimmedMemo, spentAt: spentAt)
            case let .edit(id):
                guard let record = try repository.record(with: id) else {
                    errorMessage = "기록을 찾지 못했어요."
                    return false
                }
                try repository.update(
                    record,
                    amount: amount,
                    category: category,
                    memo: trimmedMemo,
                    spentAt: spentAt
                )
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = ErrorMessage.text(for: error)
            return false
        }
    }

    public func delete() -> Bool {
        guard case let .edit(id) = mode else { return false }
        do {
            guard let record = try repository.record(with: id) else { return false }
            try repository.delete(record)
            return true
        } catch {
            errorMessage = ErrorMessage.text(for: error)
            return false
        }
    }

    /// 오늘이면 지금 시각을, 다른 날이면 정오를 기본값으로 둔다.
    private static func defaultTime(on date: Date, calendar: Calendar = .current, now: Date = .now) -> Date {
        if calendar.isDate(date, inSameDayAs: now) { return now }
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    }
}
