import Core
import SwiftUI
import UI

public struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    @State private var editorViewModel: RecordEditViewModel?
    private let onChange: () -> Void

    public init(viewModel: DayDetailViewModel, onChange: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: viewModel)
        self.onChange = onChange
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DMColor.background)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorViewModel = viewModel.makeEditorViewModel(for: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("기록 추가")
                }
            }
            .sheet(item: $editorViewModel) { editor in
                NavigationStack {
                    RecordEditView(viewModel: editor) {
                        viewModel.load()
                        onChange()
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxHeight: .infinity)

        case .empty:
            VStack(spacing: DMSpacing.l) {
                DMEmptyStateView(title: "이 날은 기록이 없어요", message: "지출을 추가해 보세요.")
                DMPrimaryButton("기록 추가", systemImage: "plus") {
                    editorViewModel = viewModel.makeEditorViewModel(for: nil)
                }
                .padding(.horizontal, DMSpacing.m)
            }
            .frame(maxHeight: .infinity)

        case let .loaded(summary, records):
            ScrollView {
                VStack(spacing: DMSpacing.m) {
                    totalCard(summary)
                    chartCard(summary)
                    recordList(records)
                }
                .padding(DMSpacing.m)
            }

        case let .failed(message):
            VStack(spacing: DMSpacing.m) {
                DMEmptyStateView(
                    title: "문제가 생겼어요",
                    message: message,
                    systemImage: "exclamationmark.triangle"
                )
                DMPrimaryButton("다시 시도") { viewModel.load() }
                    .padding(.horizontal, DMSpacing.m)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func totalCard(_ summary: SpendingSummary) -> some View {
        DMCard {
            VStack(alignment: .leading, spacing: DMSpacing.xs) {
                Text("이 날 총 지출")
                    .font(DMFont.caption)
                    .foregroundStyle(DMColor.secondaryText)
                Text(DMFormatter.won(summary.total))
                    .font(DMFont.amount)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func chartCard(_ summary: SpendingSummary) -> some View {
        DMCard {
            VStack(alignment: .leading, spacing: DMSpacing.m) {
                Text("카테고리별")
                    .font(DMFont.headline)
                DMDonutChart(slices: slices(from: summary))
            }
        }
    }

    /// 금액순이 아니라 카테고리 선언 순서로 배치한다. 이웃하는 색 조합이 항상
    /// 색약 분리도를 검증한 조합으로 유지돼, 데이터에 따라 구분이 무너지지 않는다.
    private func slices(from summary: SpendingSummary) -> [DMDonutChart.Slice] {
        let amounts = Dictionary(
            uniqueKeysWithValues: summary.byCategory.map { ($0.category, $0.amount) }
        )
        return RecordCategory.allCases.compactMap { category in
            guard let amount = amounts[category] else { return nil }
            return DMDonutChart.Slice(
                id: category.rawValue,
                label: category.displayName,
                value: amount,
                color: CategoryStyle.color(for: category)
            )
        }
    }

    private func recordList(_ records: [DayDetailViewModel.RecordItem]) -> some View {
        VStack(alignment: .leading, spacing: DMSpacing.s) {
            Text("기록 \(records.count)건")
                .font(DMFont.headline)
                .padding(.horizontal, DMSpacing.xs)

            ForEach(records) { record in
                Button {
                    editorViewModel = viewModel.makeEditorViewModel(for: record)
                } label: {
                    DMCard {
                        HStack(spacing: DMSpacing.m) {
                            Image(systemName: CategoryStyle.symbol(for: record.category))
                                .font(.system(size: 16))
                                .foregroundStyle(CategoryStyle.color(for: record.category))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.category.displayName)
                                    .font(DMFont.headline)
                                    .foregroundStyle(DMColor.primaryText)
                                Text(record.memo.isEmpty ? "메모 없음" : record.memo)
                                    .font(DMFont.caption)
                                    .foregroundStyle(DMColor.secondaryText)
                            }

                            Spacer(minLength: DMSpacing.s)

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(DMFormatter.won(record.amount))
                                    .font(DMFont.body)
                                    .foregroundStyle(DMColor.primaryText)
                                    .monospacedDigit()
                                Text(record.spentAt.formatted(.dateTime.hour().minute()))
                                    .font(DMFont.caption)
                                    .foregroundStyle(DMColor.secondaryText)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.delete(record)
                        onChange()
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
    }
}

#Preview("기록 있음") {
    NavigationStack {
        DayDetailView(
            viewModel: DayDetailViewModel(
                repository: PreviewFactory.repository(seeded: true),
                date: .now,
                calendar: .current
            )
        )
    }
}

#Preview("빈 날") {
    NavigationStack {
        DayDetailView(
            viewModel: DayDetailViewModel(
                repository: PreviewFactory.repository(seeded: false),
                date: .now,
                calendar: .current
            )
        )
    }
}

#Preview("에러") {
    NavigationStack {
        DayDetailView(
            viewModel: DayDetailViewModel(
                repository: FailingPreviewRepository(),
                date: .now,
                calendar: .current
            )
        )
    }
}
