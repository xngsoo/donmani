import Foundation
import SwiftData

@Model
public final class MoneyRecord {
    public var amount: Int
    public var category: RecordCategory
    public var memo: String
    public var spentAt: Date

    public init(
        amount: Int,
        category: RecordCategory,
        memo: String = "",
        spentAt: Date = .now
    ) {
        self.amount = amount
        self.category = category
        self.memo = memo
        self.spentAt = spentAt
    }
}
