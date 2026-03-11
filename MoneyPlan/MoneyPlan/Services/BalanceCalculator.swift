import Foundation

struct BalanceEntry {
    let planID: UUID
    let date: Date
    let runningBalance: Int
    let planName: String
}

struct BalanceCalculationResult {
    let entries: [BalanceEntry]
    let currentBalance: Int
    let lowestBalance: Int
    let firstNegativeDate: Date?
    let warningDates: [Date]
}

struct BalanceCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// 予定一覧から累計残高と警告日を算出する。
    func calculate(
        initialBalance: Int,
        plans: [TransactionPlan],
        warningThreshold: Int
    ) -> BalanceCalculationResult {
        let sortedPlans = plans.sorted(by: comparePlans)
        var runningBalance = initialBalance
        var lowestBalance = initialBalance
        var firstNegativeDate: Date?
        var warningDates = Set<Date>()
        var entries: [BalanceEntry] = []

        for plan in sortedPlans {
            runningBalance += plan.signedAmount
            lowestBalance = min(lowestBalance, runningBalance)

            let day = calendar.startOfDay(for: plan.date)
            if runningBalance < 0, firstNegativeDate == nil {
                firstNegativeDate = day
            }
            if runningBalance <= warningThreshold {
                warningDates.insert(day)
            }

            entries.append(
                BalanceEntry(
                    planID: plan.id,
                    date: plan.date,
                    runningBalance: runningBalance,
                    planName: plan.name
                )
            )
        }

        return BalanceCalculationResult(
            entries: entries,
            currentBalance: entries.last?.runningBalance ?? initialBalance,
            lowestBalance: lowestBalance,
            firstNegativeDate: firstNegativeDate,
            warningDates: warningDates.sorted()
        )
    }

    /// 一覧表示と同じ順序で予定を比較する。
    private func comparePlans(_ lhs: TransactionPlan, _ rhs: TransactionPlan) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
