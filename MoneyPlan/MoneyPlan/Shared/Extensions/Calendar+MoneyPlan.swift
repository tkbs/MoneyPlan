import Foundation

extension Calendar {
    /// 指定日の月初を返す。
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }

    /// 指定日の翌月月初を返す。
    func startOfNextMonth(for date: Date) -> Date {
        let start = startOfMonth(for: date)
        return self.date(byAdding: .month, value: 1, to: start) ?? start
    }

    /// 指定月からの月初配列を作る。
    func monthStarts(from startMonth: Date, count: Int) -> [Date] {
        guard count > 0 else { return [] }

        let normalizedStart = startOfMonth(for: startMonth)
        return (0..<count).compactMap { offset in
            date(byAdding: .month, value: offset, to: normalizedStart)
        }
    }

    /// 月初と日を元に発生日を作る。
    func occurrenceDate(in month: Date, day: Int) -> Date? {
        guard
            let dayRange = range(of: .day, in: .month, for: month),
            dayRange.contains(day)
        else {
            return nil
        }

        var components = dateComponents([.year, .month], from: month)
        components.day = day
        return date(from: components)
    }
}
