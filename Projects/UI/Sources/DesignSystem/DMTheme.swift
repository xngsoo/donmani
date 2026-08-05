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
    public static let danger = Color(.systemRed)
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
}
