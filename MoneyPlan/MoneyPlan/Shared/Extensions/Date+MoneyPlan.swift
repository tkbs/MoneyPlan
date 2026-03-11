import Foundation

extension Date {
    /// 日付を比較用の月初に正規化する。
    func monthStart(using calendar: Calendar = .current) -> Date {
        calendar.startOfMonth(for: self)
    }
}
