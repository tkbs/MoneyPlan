import Foundation
import Testing
@testable import MoneyPlan

struct DashboardSummaryBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    /// 当月集計、現在残高、直近予定をまとめて構築できる。
    @Test func buildsDashboardSummary() {
        let referenceDate = makeDate(month: 3, day: 15)
        let plans = [
            makePlan(month: 3, day: 1, flowType: .income, amount: 50_000, name: "給与"),
            makePlan(month: 3, day: 15, flowType: .expense, amount: 10_000, name: "家賃"),
            makePlan(month: 3, day: 20, flowType: .expense, amount: 30_000, name: "カード"),
            makePlan(month: 4, day: 10, flowType: .income, amount: 5_000, name: "副収入"),
        ]

        let summary = DashboardSummaryBuilder(calendar: calendar).build(
            plans: plans,
            initialBalance: 20_000,
            warningThreshold: 35_000,
            graphRange: .oneMonth,
            referenceDate: referenceDate
        )

        #expect(summary.currentBalance == 60_000)
        #expect(summary.monthlyIncomeTotal == 50_000)
        #expect(summary.monthlyExpenseTotal == 40_000)
        #expect(summary.lowestProjectedBalance == 30_000)
        #expect(summary.warningState == .warning)
        #expect(summary.upcomingPlans.map(\.name) == ["家賃", "カード", "副収入"])
        #expect(summary.graphPoints.map(\.balance) == [60_000, 30_000, 35_000])
    }

    /// 直近に警告がない場合は安全状態を返す。
    @Test func returnsSafeWarningWhenProjectionIsHealthy() {
        let referenceDate = makeDate(month: 3, day: 15)
        let plans = [
            makePlan(month: 2, day: 10, flowType: .income, amount: 30_000, name: "入金"),
            makePlan(month: 4, day: 1, flowType: .expense, amount: 5_000, name: "支払い"),
        ]

        let summary = DashboardSummaryBuilder(calendar: calendar).build(
            plans: plans,
            initialBalance: 10_000,
            warningThreshold: 3_000,
            graphRange: .all,
            referenceDate: referenceDate
        )

        #expect(summary.currentBalance == 40_000)
        #expect(summary.warningState == .none)
        #expect(summary.warningMessage == "警告はありません。")
    }

    /// テスト用の予定を作る。
    private func makePlan(
        month: Int,
        day: Int,
        flowType: FlowType,
        amount: Int,
        name: String
    ) -> TransactionPlan {
        TransactionPlan(
            date: makeDate(month: month, day: day),
            flowType: flowType,
            name: name,
            amount: amount,
            createdAt: makeDate(month: 1, day: day, hour: day),
            updatedAt: makeDate(month: 1, day: day, hour: day)
        )
    }

    /// テスト用の日付を作る。
    private func makeDate(month: Int, day: Int, hour: Int = 0) -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: 2026,
            month: month,
            day: day,
            hour: hour
        )
        return components.date ?? .distantPast
    }
}
