import Core
import SwiftUI
import UI

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DMColor.background)
                .navigationTitle("돈마니")
        }
        .task { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()

        case .empty:
            VStack(spacing: DMSpacing.l) {
                DMEmptyStateView(title: "기록이 없어요", message: "첫 지출을 기록해 보세요.")
                DMPrimaryButton("샘플 기록 추가", systemImage: "plus") {
                    viewModel.addSample(amount: 12_000, category: .food, memo: "점심")
                }
                .padding(.horizontal, DMSpacing.m)
            }

        case let .loaded(summary, records):
            ScrollView {
                VStack(spacing: DMSpacing.m) {
                    summaryCard(summary)
                    recordList(records)
                }
                .padding(DMSpacing.m)
            }

        case let .failed(message):
            VStack(spacing: DMSpacing.m) {
                DMEmptyStateView(title: "문제가 생겼어요", message: message, systemImage: "exclamationmark.triangle")
                DMPrimaryButton("다시 시도") { viewModel.load() }
                    .padding(.horizontal, DMSpacing.m)
            }
        }
    }

    private func summaryCard(_ summary: SpendingSummary) -> some View {
        DMCard {
            VStack(alignment: .leading, spacing: DMSpacing.s) {
                Text("전체 지출")
                    .font(DMFont.caption)
                    .foregroundStyle(DMColor.secondaryText)
                Text(DMFormatter.won(summary.total))
                    .font(DMFont.amount)

                ForEach(summary.byCategory) { item in
                    HStack {
                        Text(item.category.displayName)
                        Spacer()
                        Text(DMFormatter.won(item.amount))
                            .foregroundStyle(DMColor.secondaryText)
                    }
                    .font(DMFont.body)
                }
            }
        }
    }

    private func recordList(_ records: [HomeViewModel.RecordItem]) -> some View {
        VStack(spacing: DMSpacing.s) {
            ForEach(records) { record in
                DMCard {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: DMSpacing.xs) {
                            Text(record.category.displayName).font(DMFont.headline)
                            Text(record.memo.isEmpty ? "메모 없음" : record.memo)
                                .font(DMFont.caption)
                                .foregroundStyle(DMColor.secondaryText)
                        }
                        Spacer()
                        Text(DMFormatter.won(record.amount)).font(DMFont.body)
                    }
                }
            }
        }
    }
}

@MainActor
private final class FailingPreviewRepository: RecordRepository {
    func fetchAll() throws -> [MoneyRecord] { throw RecordRepositoryError.persistenceFailed("preview") }
    func fetch(in dateInterval: DateInterval) throws -> [MoneyRecord] { try fetchAll() }
    func add(amount: Int, category: RecordCategory, memo: String, spentAt: Date) throws -> MoneyRecord {
        throw RecordRepositoryError.persistenceFailed("preview")
    }
    func delete(_ record: MoneyRecord) throws { throw RecordRepositoryError.persistenceFailed("preview") }
}

@MainActor
private func previewViewModel(records: [(Int, RecordCategory, String)]) -> HomeViewModel {
    do {
        let repository = SwiftDataRecordRepository(container: try ModelContainerFactory.make(inMemory: true))
        for (amount, category, memo) in records {
            try repository.add(amount: amount, category: category, memo: memo, spentAt: .now)
        }
        return HomeViewModel(repository: repository)
    } catch {
        return HomeViewModel(repository: FailingPreviewRepository())
    }
}

#Preview("데이터 있음") {
    HomeView(viewModel: previewViewModel(records: [
        (12_000, .food, "점심"),
        (2_800, .transport, "지하철"),
        (30_000, .culture, "공연"),
    ]))
}

#Preview("빈 상태") {
    HomeView(viewModel: previewViewModel(records: []))
}

#Preview("에러") {
    HomeView(viewModel: HomeViewModel(repository: FailingPreviewRepository()))
}
