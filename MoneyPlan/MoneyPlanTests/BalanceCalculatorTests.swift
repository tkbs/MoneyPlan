import Foundation
import Testing
@testable import MoneyPlan

struct BalanceCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    /// 入出金混在時に累計残高と最低残高を計算できる。
    @Test func calculatesRunningBalance() {
        let plans = [
            makePlan(day: 10, flowType: .income, amount: 30_000),
            makePlan(day: 15, flowType: .expense, amount: 50_000),
            makePlan(day: 20, flowType: .income, amount: 10_000),
        ]

        let result = BalanceCalculator(calendar: calendar).calculate(
            initialBalance: 20_000,
            plans: plans,
            warningThreshold: 5_000
        )

        #expect(result.entries.map(\.runningBalance) == [50_000, 0, 10_000])
        #expect(result.currentBalance == 10_000)
        #expect(result.lowestBalance == 0)
        #expect(result.firstNegativeDate == nil)
    }

    /// 同日内の表示順と作成日時で順序が安定する。
    @Test func sortsPlansByDesignedOrder() {
        let baseDate = makeDate(day: 10)
        let lateCreatedPlan = TransactionPlan(
            date: baseDate,
            flowType: .expense,
            name: "B",
            amount: 4_000,
            sortOrder: 0,
            createdAt: makeDate(day: 1, hour: 12),
            updatedAt: makeDate(day: 1, hour: 12)
        )
        let earlyCreatedPlan = TransactionPlan(
            date: baseDate,
            flowType: .expense,
            name: "A",
            amount: 2_000,
            sortOrder: 0,
            createdAt: makeDate(day: 1, hour: 9),
            updatedAt: makeDate(day: 1, hour: 9)
        )
        let laterSortOrderPlan = TransactionPlan(
            date: baseDate,
            flowType: .income,
            name: "C",
            amount: 10_000,
            sortOrder: 1,
            createdAt: makeDate(day: 1, hour: 8),
            updatedAt: makeDate(day: 1, hour: 8)
        )

        let result = BalanceCalculator(calendar: calendar).calculate(
            initialBalance: 0,
            plans: [laterSortOrderPlan, lateCreatedPlan, earlyCreatedPlan],
            warningThreshold: -1
        )

        #expect(result.entries.map(\.planName) == ["A", "B", "C"])
        #expect(result.entries.map(\.runningBalance) == [-2_000, -6_000, 4_000])
    }

    /// 負残高開始時でも警告日と不足日を返せる。
    @Test func detectsNegativeAndWarningDates() {
        let result = BalanceCalculator(calendar: calendar).calculate(
            initialBalance: -1_000,
            plans: [makePlan(day: 11, flowType: .expense, amount: 500)],
            warningThreshold: 0
        )

        #expect(result.currentBalance == -1_500)
        #expect(result.lowestBalance == -1_500)
        #expect(result.firstNegativeDate == makeDate(day: 11))
        #expect(result.warningDates == [makeDate(day: 11)])
    }

    /// テスト用の予定を作る。
    private func makePlan(day: Int, flowType: FlowType, amount: Int) -> TransactionPlan {
        TransactionPlan(
            date: makeDate(day: day),
            flowType: flowType,
            name: "plan-\(day)",
            amount: amount,
            createdAt: makeDate(day: 1, hour: day),
            updatedAt: makeDate(day: 1, hour: day)
        )
    }

    /// テスト用の日付を作る。
    private func makeDate(day: Int, hour: Int = 0) -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: day,
            hour: hour
        )
        return components.date ?? .distantPast
    }
}
