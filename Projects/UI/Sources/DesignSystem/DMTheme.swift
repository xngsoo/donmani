import SwiftUI

public enum DMSpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
}

public enum DMRadius {
    public static let card: CGFloat = 16
    public static let button: CGFloat = 12
}

public enum DMColor {
    public static let accent = Color.accentColor
    public static let background = Color(.systemGroupedBackground)
    public static let surface = Color(.secondarySystemGroupedBackground)
    public static let primaryText = Color(.label)
    public static let secondaryText = Color(.secondaryLabel)
    public static let tertiaryText = Color(.tertiaryLabel)
    public static let separator = Color(.separator)
    public static let danger = Color(.systemRed)

    /// 카테고리 식별용 고정 순서 팔레트. 순환시키지 않고 슬롯을 엔티티에 고정한다.
    /// 라이트/다크 각각 색약 분리도·대비 검증을 통과한 값이다.
    public static let chartPalette: [Color] = [
        dynamic(light: 0x2A78D6, dark: 0x3987E5),
        dynamic(light: 0xEB6834, dark: 0xD95926),
        dynamic(light: 0x1BAF7A, dark: 0x199E70),
        dynamic(light: 0xEDA100, dark: 0xC98500),
        dynamic(light: 0xE87BA4, dark: 0xD55181),
        dynamic(light: 0x008300, dark: 0x008300),
    ]

    public static func chartColor(slot: Int) -> Color {
        chartPalette[slot % chartPalette.count]
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

public enum DMFont {
    public static let title = Font.system(.title2, design: .rounded, weight: .bold)
    public static let headline = Font.system(.headline, design: .rounded)
    public static let body = Font.system(.body, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)
    public static let amount = Font.system(.largeTitle, design: .rounded, weight: .heavy)
}

public enum DMFormatter {
    public static func won(_ amount: Int) -> String {
        "\(amount.formatted(.number.grouping(.automatic)))원"
    }

    /// 달력 셀처럼 폭이 좁은 곳에서 쓰는 축약 표기. 만 단위부터 줄인다.
    public static func compactWon(_ amount: Int) -> String {
        let magnitude = abs(amount)
        let sign = amount < 0 ? "-" : ""

        switch magnitude {
        case 100_000_000...:
            return sign + trimmed(Double(magnitude) / 100_000_000) + "억"
        case 10_000...:
            return sign + trimmed(Double(magnitude) / 10_000) + "만"
        default:
            return sign + magnitude.formatted(.number.grouping(.automatic))
        }
    }

    public static func percent(_ value: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        return (Double(value) / Double(total)).formatted(.percent.precision(.fractionLength(0)))
    }

    private static func trimmed(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
    }
}
