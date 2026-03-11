import Foundation

struct DashboardSummaryBuilder {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// ダッシュボード表示用の集計結果を構築する。
    func build(
        plans: [TransactionPlan],
        initialBalance: Int,
        warningThreshold: Int,
        graphRange: DashboardGraphRange,
        referenceDate: Date = .now
    ) -> DashboardSummary {
        let calculator = BalanceCalculator(calendar: calendar)
        let calculation = calculator.calculate(
            initialBalance: initialBalance,
            plans: plans,
            warningThreshold: warningThreshold
        )
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let currentBalance = balance(
            on: referenceDay,
            from: calculation.entries,
            initialBalance: initialBalance
        )
        let currentMonthPlans = plans.filter { plan in
            calendar.isDate(plan.date, equalTo: referenceDay, toGranularity: .month)
        }
        let futureEntries = calculation.entries.filter { entry in
            calendar.startOfDay(for: entry.date) >= referenceDay
        }
        let projectedBalances = [currentBalance] + futureEntries.map(\.runningBalance)
        let lowestProjectedBalance = projectedBalances.min() ?? currentBalance
        let warningState = BalanceWarningState.from(
            balance: lowestProjectedBalance,
            warningThreshold: warningThreshold
        )

        return DashboardSummary(
            currentBalance: currentBalance,
            monthlyIncomeTotal: currentMonthPlans
                .filter { $0.flowType == .income }
                .reduce(0) { $0 + $1.amount },
            monthlyExpenseTotal: currentMonthPlans
                .filter { $0.flowType == .expense }
                .reduce(0) { $0 + $1.amount },
            lowestProjectedBalance: lowestProjectedBalance,
            warningState: warningState,
            warningMessage: makeWarningMessage(
                currentBalance: currentBalance,
                futureEntries: futureEntries,
                warningThreshold: warningThreshold,
                referenceDay: referenceDay
            ),
            graphRange: graphRange,
            graphPoints: makeGraphPoints(
                entries: calculation.entries,
                currentBalance: currentBalance,
                graphRange: graphRange,
                referenceDay: referenceDay
            ),
            upcomingPlans: makeUpcomingPlans(
                plans: plans,
                entries: calculation.entries,
                warningThreshold: warningThreshold,
                referenceDay: referenceDay
            )
        )
    }

    /// 指定日の終了時点残高を返す。
    private func balance(
        on day: Date,
        from entries: [BalanceEntry],
        initialBalance: Int
    ) -> Int {
        entries.last(where: { calendar.startOfDay(for: $0.date) <= day })?.runningBalance ?? initialBalance
    }

    /// 同日複数予定を日次終値へまとめる。
    private func dailyBalancePoints(from entries: [BalanceEntry]) -> [BalancePoint] {
        var points: [BalancePoint] = []

        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            if let lastPoint = points.last, calendar.isDate(lastPoint.date, inSameDayAs: day) {
                points.removeLast()
            }
            points.append(BalancePoint(date: day, balance: entry.runningBalance))
        }

        return points
    }

    /// 表示範囲に応じたグラフ点を返す。
    private func makeGraphPoints(
        entries: [BalanceEntry],
        currentBalance: Int,
        graphRange: DashboardGraphRange,
        referenceDay: Date
    ) -> [BalancePoint] {
        var points = dailyBalancePoints(from: entries)

        switch graphRange {
        case .oneMonth:
            let endDay = calendar.date(
                byAdding: .day,
                value: MoneyPlanConstants.dashboardGraphDayCount,
                to: referenceDay
            ) ?? referenceDay
            points = points.filter { point in
                point.date >= referenceDay && point.date < endDay
            }
        case .all:
            break
        }

        if points.contains(where: { calendar.isDate($0.date, inSameDayAs: referenceDay) }) == false {
            points.append(BalancePoint(date: referenceDay, balance: currentBalance))
        }

        let sortedPoints = points.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }
            return lhs.balance < rhs.balance
        }

        return sortedPoints.isEmpty ? [BalancePoint(date: referenceDay, balance: currentBalance)] : sortedPoints
    }

    /// 直近予定の表示行を構築する。
    private func makeUpcomingPlans(
        plans: [TransactionPlan],
        entries: [BalanceEntry],
        warningThreshold: Int,
        referenceDay: Date
    ) -> [UpcomingPlanRowModel] {
        let runningBalanceMap = Dictionary(
            uniqueKeysWithValues: entries.map { ($0.planID, $0.runningBalance) }
        )

        return plans
            .filter { calendar.startOfDay(for: $0.date) >= referenceDay }
            .prefix(MoneyPlanConstants.dashboardUpcomingPlanLimit)
            .map { plan in
                let runningBalance = runningBalanceMap[plan.id] ?? 0
                return UpcomingPlanRowModel(
                    planID: plan.id,
                    date: plan.date,
                    name: plan.name,
                    displayAmount: CurrencyFormatter.signedString(from: plan.signedAmount),
                    memo: plan.memo,
                    warningState: .from(
                        balance: runningBalance,
                        warningThreshold: warningThreshold
                    ),
                    isAutoGenerated: plan.isAutoGenerated,
                    flowType: plan.flowType
                )
            }
    }

    /// 警告カードの説明文を返す。
    private func makeWarningMessage(
        currentBalance: Int,
        futureEntries: [BalanceEntry],
        warningThreshold: Int,
        referenceDay: Date
    ) -> String {
        if currentBalance < 0 {
            return "現在の残高が不足しています。"
        }
        if currentBalance <= warningThreshold {
            return "現在の残高が警告閾値以下です。"
        }
        if let firstNegativeEntry = futureEntries.first(where: { $0.runningBalance < 0 }) {
            return "\(formatted(date: firstNegativeEntry.date)) に残高不足の見込みです。"
        }
        if let firstWarningEntry = futureEntries.first(where: { $0.runningBalance <= warningThreshold }) {
            if calendar.startOfDay(for: firstWarningEntry.date) == referenceDay {
                return "本日の残高が警告閾値以下です。"
            }
            return "\(formatted(date: firstWarningEntry.date)) に警告閾値以下になる見込みです。"
        }
        return "警告はありません。"
    }

    /// 警告文向けの日付文字列を返す。
    private func formatted(date: Date) -> String {
        date.formatted(.dateTime.month().day())
    }
}
