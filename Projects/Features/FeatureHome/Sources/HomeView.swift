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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(DMColor.background)
                .navigationTitle("돈마니")
                .navigationDestination(item: $viewModel.selectedDay) { day in
                    DayDetailView(
                        viewModel: viewModel.makeDayViewModel(for: day.date),
                        onChange: { viewModel.load() }
                    )
                }
        }
        .onAppear { viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxHeight: .infinity)

        case let .loaded(month):
            ScrollView {
                VStack(spacing: DMSpacing.m) {
                    monthHeader
                    calendarCard(month)
                    monthSummary(month)
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

    private var monthHeader: some View {
        HStack {
            Button { viewModel.moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("이전 달")

            Spacer()
            Text(viewModel.monthTitle)
                .font(DMFont.title)
            Spacer()

            Button { viewModel.moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("다음 달")
        }
        .font(DMFont.headline)
        .foregroundStyle(DMColor.primaryText)
        .padding(.horizontal, DMSpacing.s)
    }

    private func calendarCard(_ month: HomeViewModel.Month) -> some View {
        DMCard {
            DMCalendarView(
                weeks: month.grid.weeks.map { week in
                    week.map { day in
                        DMCalendarView.DayItem(
                            date: day.date,
                            number: day.number,
                            isWithinMonth: day.isWithinMonth,
                            isToday: viewModel.isToday(day.date),
                            amount: month.dailyTotals[day.date]
                        )
                    }
                },
                weekdaySymbols: viewModel.weekdaySymbols,
                selectedDate: viewModel.selectedDay?.date,
                onSelect: { viewModel.select($0) }
            )
        }
    }

    private func monthSummary(_ month: HomeViewModel.Month) -> some View {
        VStack(spacing: DMSpacing.m) {
            DMCard {
                VStack(alignment: .leading, spacing: DMSpacing.xs) {
                    Text("이번 달 지출")
                        .font(DMFont.caption)
                        .foregroundStyle(DMColor.secondaryText)
                    Text(DMFormatter.won(month.total))
                        .font(DMFont.amount)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("기록 \(month.recordCount)건")
                        .font(DMFont.caption)
                        .foregroundStyle(DMColor.secondaryText)
                }
            }

            if month.recordCount == 0 {
                Text("날짜를 눌러 첫 지출을 기록해 보세요.")
                    .font(DMFont.caption)
                    .foregroundStyle(DMColor.secondaryText)
            }

            DMPrimaryButton("오늘 기록하기", systemImage: "plus") {
                viewModel.selectToday()
            }
        }
    }
}

#Preview("기록 있음") {
    HomeView(viewModel: PreviewFactory.homeViewModel(seeded: true))
}

#Preview("빈 달") {
    HomeView(viewModel: PreviewFactory.homeViewModel(seeded: false))
}

#Preview("에러") {
    HomeView(viewModel: HomeViewModel(repository: FailingPreviewRepository()))
}
