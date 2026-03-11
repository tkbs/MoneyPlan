import Foundation

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    /// 金額を日本円表記へ整形する。
    static func string(from amount: Int) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "¥\(amount)"
    }

    /// 符号付き金額を日本円表記へ整形する。
    static func signedString(from amount: Int) -> String {
        if amount > 0 {
            return "+\(string(from: amount))"
        }
        if amount < 0 {
            return "-\(string(from: abs(amount)))"
        }
        return string(from: amount)
    }
}
