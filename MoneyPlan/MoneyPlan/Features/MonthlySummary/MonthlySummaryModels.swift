import Foundation

struct MonthlySummary {
    let targetMonth: Date
    let incomeTotal: Int
    let expenseTotal: Int
    let endingBalance: Int
    let lowestBalance: Int
    let dailySummaries: [DailySummaryRowModel]

    /// 表示前の空サマリーを返す。
    static func empty(for targetMonth: Date) -> MonthlySummary {
        MonthlySummary(
            targetMonth: targetMonth,
            incomeTotal: 0,
            expenseTotal: 0,
            endingBalance: 0,
            lowestBalance: 0,
            dailySummaries: []
        )
    }
}

struct DailySummaryRowModel: Identifiable {
    let date: Date
    let incomeTotal: Int
    let expenseTotal: Int
    let planCount: Int
    let endingBalance: Int
    let warningState: BalanceWarningState

    var id: Date { date }
}
