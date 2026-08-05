import Foundation
import SwiftData

public enum ModelContainerFactory {
    public static let models: [any PersistentModel.Type] = [MoneyRecord.self]

    /// `Schema` 인스턴스는 컨테이너에 귀속되므로 재사용하지 않고 매번 새로 만든다.
    public static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
