import Core
import FeatureHome
import SwiftData
import SwiftUI

@main
struct DonmaniApp: App {
    @State private var composition = AppComposition()

    var body: some Scene {
        WindowGroup {
            switch composition.state {
            case let .ready(container, repository):
                HomeView(viewModel: HomeViewModel(repository: repository))
                    .modelContainer(container)
            case let .failed(message):
                LaunchFailureView(message: message) { composition.retry() }
            }
        }
    }
}

/// SwiftData 컨테이너 생성은 실패할 수 있으므로 앱 진입점에서 한 번만 시도하고 결과를 상태로 들고 간다.
@MainActor
@Observable
final class AppComposition {
    enum State {
        case ready(ModelContainer, any RecordRepository)
        case failed(message: String)
    }

    private(set) var state: State

    init() {
        state = Self.makeState()
    }

    func retry() {
        state = Self.makeState()
    }

    private static func makeState() -> State {
        do {
            let container = try ModelContainerFactory.make()
            return .ready(container, SwiftDataRecordRepository(container: container))
        } catch {
            return .failed(message: "데이터를 불러오지 못했어요.\n앱을 다시 실행해 주세요.")
        }
    }
}
