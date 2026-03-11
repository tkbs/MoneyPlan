import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var graphRange: DashboardGraphRange = .oneMonth
    var summary: DashboardSummary
    var editingPlan: TransactionPlan?
    var isShowingEditor = false
    var selectedMonth: Date
    var isShowingMonthlySummary = false

    private let calendar: Calendar

    init(referenceDate: Date = .now, calendar: Calendar = .current) {
        self.calendar = calendar
        self.selectedMonth = calendar.startOfMonth(for: referenceDate)
        self.summary = .empty(graphRange: .oneMonth, referenceDate: referenceDate)
    }

    /// 最新データから表示サマリーを再構築する。
    func reload(
        plans: [TransactionPlan],
        initialBalance: Int,
        warningThreshold: Int,
        referenceDate: Date = .now
    ) {
        let builder = DashboardSummaryBuilder(calendar: calendar)
        summary = builder.build(
            plans: plans,
            initialBalance: initialBalance,
            warningThreshold: warningThreshold,
            graphRange: graphRange,
            referenceDate: referenceDate
        )
        selectedMonth = calendar.startOfMonth(for: referenceDate)
    }

    /// 予定編集シートを開く。
    func presentEdit(for plan: TransactionPlan) {
        editingPlan = plan
        isShowingEditor = true
    }

    /// 新規予定作成シートを開く。
    func presentCreate() {
        editingPlan = nil
        isShowingEditor = true
    }

    /// 月次サマリーを対象月で開く。
    func presentMonthlySummary(for month: Date) {
        selectedMonth = calendar.startOfMonth(for: month)
        isShowingMonthlySummary = true
    }
}
