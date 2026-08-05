import Charts
import SwiftUI

/// 부분-전체를 한눈에 보여주는 도넛. 조각은 6개 이하로 유지하고,
/// 색만으로 식별하지 않도록 금액·비율 표를 항상 함께 낸다.
/// 전달하는 순서가 곧 링의 이웃 관계이므로, 호출자는 색 분리도를 검증한
/// 고정 순서로 넘겨야 한다(금액순 정렬 금지).
public struct DMDonutChart: View {
    public struct Slice: Identifiable, Equatable {
        public let id: String
        public let label: String
        public let value: Int
        public let color: Color

        public init(id: String, label: String, value: Int, color: Color) {
            self.id = id
            self.label = label
            self.value = value
            self.color = color
        }
    }

    private let slices: [Slice]
    private let centerCaption: String

    private var total: Int { slices.reduce(0) { $0 + $1.value } }

    public init(slices: [Slice], centerCaption: String = "합계") {
        self.slices = slices
        self.centerCaption = centerCaption
    }

    public var body: some View {
        VStack(spacing: DMSpacing.m) {
            chart
            legend
        }
    }

    private var chart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value(slice.label, slice.value),
                innerRadius: .ratio(0.62),
                angularInset: 2
            )
            .cornerRadius(3)
            .foregroundStyle(slice.color)
        }
        .chartLegend(.hidden)
        .frame(height: 180)
        .overlay {
            VStack(spacing: 2) {
                Text(centerCaption)
                    .font(DMFont.caption)
                    .foregroundStyle(DMColor.secondaryText)
                Text(DMFormatter.won(total))
                    .font(DMFont.headline)
                    .foregroundStyle(DMColor.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, DMSpacing.l)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("카테고리별 지출 비율 그래프, 합계 \(DMFormatter.won(total))")
    }

    private var legend: some View {
        VStack(spacing: DMSpacing.s) {
            ForEach(slices) { slice in
                HStack(spacing: DMSpacing.s) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(slice.color)
                        .frame(width: 10, height: 10)
                    Text(slice.label)
                        .font(DMFont.body)
                        .foregroundStyle(DMColor.primaryText)
                    Spacer(minLength: DMSpacing.s)
                    Text(DMFormatter.percent(slice.value, of: total))
                        .font(DMFont.caption)
                        .foregroundStyle(DMColor.secondaryText)
                        .monospacedDigit()
                    Text(DMFormatter.won(slice.value))
                        .font(DMFont.body)
                        .foregroundStyle(DMColor.primaryText)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview("도넛") {
    DMDonutChart(slices: [
        .init(id: "food", label: "식비", value: 182_000, color: DMColor.chartColor(slot: 0)),
        .init(id: "transport", label: "교통", value: 64_000, color: DMColor.chartColor(slot: 1)),
        .init(id: "living", label: "생활", value: 41_500, color: DMColor.chartColor(slot: 2)),
        .init(id: "culture", label: "문화", value: 30_000, color: DMColor.chartColor(slot: 3)),
    ])
    .padding()
    .background(DMColor.background)
}

#Preview("한 조각") {
    DMDonutChart(slices: [
        .init(id: "saving", label: "저축", value: 500_000, color: DMColor.chartColor(slot: 4)),
    ])
    .padding()
    .background(DMColor.background)
}
