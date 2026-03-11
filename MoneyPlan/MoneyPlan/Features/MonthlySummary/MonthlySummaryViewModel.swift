import Foundation
import Observation

@Observable
final class MonthlySummaryViewModel {
    var targetMonth: Date
    var summary: MonthlySummary

    private let calendar: Calendar

    init(targetMonth: Date = .now, calendar: Calendar = .current) {
        let normalizedMonth = calendar.startOfMonth(for: targetMonth)
        self.calendar = calendar
        self.targetMonth = normalizedMonth
        self.summary = .empty(for: normalizedMonth)
    }

    /// 前月へ移動する。
    func showPreviousMonth() {
        targetMonth = calendar.date(byAdding: .month, value: -1, to: targetMonth) ?? targetMonth
    }

    /// 翌月へ移動する。
    func showNextMonth() {
        targetMonth = calendar.date(byAdding: .month, value: 1, to: targetMonth) ?? targetMonth
    }

    /// 最新データから月次サマリーを再構築する。
    func reload(
        plans: [TransactionPlan],
        initialBalance: Int,
        warningThreshold: Int
    ) {
        let builder = MonthlySummaryBuilder(calendar: calendar)
        summary = builder.build(
            plans: plans,
            initialBalance: initialBalance,
            warningThreshold: warningThreshold,
            targetMonth: targetMonth
        )
    }
}
