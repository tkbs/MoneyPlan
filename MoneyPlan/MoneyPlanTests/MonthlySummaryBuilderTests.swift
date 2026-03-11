import Foundation
import Testing
@testable import MoneyPlan

struct MonthlySummaryBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    /// 月内合計、月末残高、最低残高を正しく集計できる。
    @Test func buildsMonthlySummary() {
        let plans = [
            makePlan(month: 2, day: 25, flowType: .income, amount: 5_000, name: "前月入金"),
            makePlan(month: 3, day: 5, flowType: .expense, amount: 3_000, name: "固定費"),
            makePlan(month: 3, day: 10, flowType: .income, amount: 8_000, name: "臨時収入"),
            makePlan(month: 3, day: 28, flowType: .expense, amount: 20_000, name: "支払い"),
            makePlan(month: 4, day: 3, flowType: .income, amount: 2_000, name: "翌月入金"),
        ]

        let summary = MonthlySummaryBuilder(calendar: calendar).build(
            plans: plans,
            initialBalance: 10_000,
            warningThreshold: 0,
            targetMonth: makeDate(month: 3, day: 1)
        )

        #expect(summary.incomeTotal == 8_000)
        #expect(summary.expenseTotal == 23_000)
        #expect(summary.endingBalance == 0)
        #expect(summary.lowestBalance == 0)
        #expect(summary.dailySummaries.count == 3)
        #expect(summary.dailySummaries.map(\.endingBalance) == [12_000, 20_000, 0])
        #expect(summary.dailySummaries.last?.warningState == .warning)
    }

    /// 対象月に予定がなくても開始時点残高を返せる。
    @Test func keepsStartingBalanceWhenMonthHasNoPlans() {
        let plans = [
            makePlan(month: 2, day: 5, flowType: .income, amount: 4_000, name: "前月"),
            makePlan(month: 4, day: 12, flowType: .expense, amount: 2_000, name: "翌月"),
        ]

        let summary = MonthlySummaryBuilder(calendar: calendar).build(
            plans: plans,
            initialBalance: 1_000,
            warningThreshold: 0,
            targetMonth: makeDate(month: 3, day: 1)
        )

        #expect(summary.incomeTotal == 0)
        #expect(summary.expenseTotal == 0)
        #expect(summary.endingBalance == 5_000)
        #expect(summary.lowestBalance == 5_000)
        #expect(summary.dailySummaries.isEmpty)
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
