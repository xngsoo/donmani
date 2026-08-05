import Foundation

public enum RecordCategory: String, Codable, CaseIterable, Sendable {
    case food
    case transport
    case living
    case culture
    case saving
    case etc

    public var displayName: String {
        switch self {
        case .food: "식비"
        case .transport: "교통"
        case .living: "생활"
        case .culture: "문화"
        case .saving: "저축"
        case .etc: "기타"
        }
    }
}
