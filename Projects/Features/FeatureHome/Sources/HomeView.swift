import Core
import SwiftUI
import UI

public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    /// 월 전환 애니메이션 방향. 스와이프·화살표 어느 쪽으로 이동했는지에 맞춰 슬라이드한다.
    @State private var isMovingForward = true

    private let swipeThreshold: CGFloat = 50

    public init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: DMSpacing.m) {
                appTitle
                content
            }
            .padding(.horizontal, DMSpacing.m)
            .padding(.top, DMSpacing.s)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DMColor.background)
            .safeAreaInset(edge: .bottom) { bottomBar }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $viewModel.selectedDay) { day in
                DayDetailView(
                    viewModel: viewModel.makeDayViewModel(for: day.date),
                    onChange: { viewModel.load() }
                )
            }
        }
        .onAppear { viewModel.load() }
    }

    private var appTitle: some View {
        HStack {
            Text("돈마니")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(DMColor.primaryText)
            Spacer()
        }
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxHeight: .infinity)

        case let .loaded(month):
            VStack(spacing: DMSpacing.m) {
                monthHeader
                calendarCard(month)
                    .frame(maxHeight: .infinity)
                monthSummary(month)
            }

        case let .failed(message):
            VStack(spacing: DMSpacing.m) {
                Spacer(minLength: 0)
                DMEmptyStateView(
                    title: "문제가 생겼어요",
                    message: message,
                    systemImage: "exclamationmark.triangle"
                )
                DMPrimaryButton("다시 시도") { viewModel.load() }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if case .loaded = viewModel.state {
            DMPrimaryButton("오늘 기록하기", systemImage: "plus") {
                viewModel.selectToday()
            }
            .padding(.horizontal, DMSpacing.m)
            .padding(.top, DMSpacing.s)
            .background(.bar)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { move(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("이전 달")

            Spacer()
            Text(viewModel.monthTitle)
                .font(DMFont.title)
                .contentTransition(.numericText())
            Spacer()

            Button { move(by: 1) } label: {
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
        .id(month.grid.monthStart)
        .transition(
            .asymmetric(
                insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
                removal: .opacity
            )
        )
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard let step = HomeViewModel.monthStep(
                        horizontal: value.translation.width,
                        vertical: value.translation.height,
                        threshold: swipeThreshold
                    ) else { return }
                    move(by: step)
                }
        )
        .accessibilityAction(named: "이전 달") { move(by: -1) }
        .accessibilityAction(named: "다음 달") { move(by: 1) }
    }

    private func monthSummary(_ month: HomeViewModel.Month) -> some View {
        DMCard {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: DMSpacing.xs) {
                    Text("이번 달 지출")
                        .font(DMFont.caption)
                        .foregroundStyle(DMColor.secondaryText)
                    Text(DMFormatter.won(month.total))
                        .font(DMFont.amount)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                }
                Spacer(minLength: DMSpacing.s)
                Text(month.recordCount == 0 ? "기록 없음" : "기록 \(month.recordCount)건")
                    .font(DMFont.caption)
                    .foregroundStyle(DMColor.secondaryText)
            }
        }
    }

    private func move(by value: Int) {
        isMovingForward = value > 0
        withAnimation(.snappy(duration: 0.25)) {
            viewModel.moveMonth(by: value)
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
