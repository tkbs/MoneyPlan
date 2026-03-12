import Foundation

struct MonthlySummaryBuilder {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// 月次サマリー表示用の集計結果を構築する。
    func build(
        plans: [TransactionPlan],
        initialBalance: Int,
        warningThreshold: Int,
        targetMonth: Date
    ) -> MonthlySummary {
        let normalizedMonth = calendar.startOfMonth(for: targetMonth)
        let monthEnd = calendar.startOfNextMonth(for: normalizedMonth)
        let calculator = BalanceCalculator(calendar: calendar)
        let calculation = calculator.calculate(
            initialBalance: initialBalance,
            plans: plans,
            warningThreshold: warningThreshold
        )
        let monthPlans = plans.filter { plan in
            plan.date >= normalizedMonth && plan.date < monthEnd
        }
        let startingBalance = calculation.entries
            .last(where: { $0.date < normalizedMonth })?
            .runningBalance ?? initialBalance
        let monthEntries = calculation.entries.filter { entry in
            entry.date >= normalizedMonth && entry.date < monthEnd
        }
        var dailyEndingBalance: [Date: Int] = [:]
        for entry in monthEntries {
            dailyEndingBalance[calendar.startOfDay(for: entry.date)] = entry.runningBalance
        }
        let groupedPlans = Dictionary(grouping: monthPlans) { plan in
            calendar.startOfDay(for: plan.date)
        }
        let dailySummaries = groupedPlans.keys.sorted().map { day in
            let plansForDay = groupedPlans[day] ?? []
            let endingBalance = dailyEndingBalance[day] ?? startingBalance

            return DailySummaryRowModel(
                date: day,
                incomeTotal: plansForDay.totalAmount(for: .income),
                expenseTotal: plansForDay.totalAmount(for: .expense),
                planCount: plansForDay.count,
                endingBalance: endingBalance,
                warningState: .from(balance: endingBalance, warningThreshold: warningThreshold)
            )
        }

        return MonthlySummary(
            targetMonth: normalizedMonth,
            incomeTotal: monthPlans.totalAmount(for: .income),
            expenseTotal: monthPlans.totalAmount(for: .expense),
            endingBalance: monthEntries.last?.runningBalance ?? startingBalance,
            lowestBalance: ([startingBalance] + monthEntries.map(\.runningBalance)).min() ?? startingBalance,
            dailySummaries: dailySummaries
        )
    }
}
