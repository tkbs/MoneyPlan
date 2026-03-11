import Foundation
import Observation

@Observable
final class RecurringPlanListViewModel {
    var plans: [RecurringPlanRowModel] = []
    var editingPlan: RecurringPlan?
    var isShowingEditor = false
    var deletingPlan: RecurringPlan?

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// 新規作成シートを開く。
    func presentCreate() {
        editingPlan = nil
        isShowingEditor = true
    }

    /// 編集シートを開く。
    func presentEdit(for plan: RecurringPlan) {
        editingPlan = plan
        isShowingEditor = true
    }

    /// 定期予定を表示用の行モデルへ変換する。
    func reload(plans sourcePlans: [RecurringPlan], referenceDate: Date = .now) {
        let normalizedReferenceDate = calendar.startOfDay(for: referenceDate)
        plans = sourcePlans.map { plan in
            RecurringPlanRowModel(
                planID: plan.id,
                name: plan.name,
                displayAmount: CurrencyFormatter.signedString(from: plan.signedAmount),
                note: plan.note,
                dayDescription: "毎月\(plan.dayOfMonth)日",
                nextOccurrenceDescription: nextOccurrenceDescription(for: plan, referenceDate: normalizedReferenceDate),
                isActive: plan.isActive,
                flowType: plan.flowType
            )
        }
    }

    /// 次回生成予定日または停止状態を表示文言へ変換する。
    private func nextOccurrenceDescription(for plan: RecurringPlan, referenceDate: Date) -> String {
        guard plan.isActive else {
            return "停止中"
        }

        guard let nextOccurrence = nextOccurrenceDate(for: plan, referenceDate: referenceDate) else {
            return "次回予定なし"
        }

        let formattedDate = nextOccurrence.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
        )
        return "次回 \(formattedDate)"
    }

    /// 定期予定の次回発生日を計算する。
    private func nextOccurrenceDate(for plan: RecurringPlan, referenceDate: Date) -> Date? {
        let startMonth = calendar.startOfMonth(for: plan.startMonth)
        let referenceMonth = calendar.startOfMonth(for: referenceDate)
        var candidateMonth = max(startMonth, referenceMonth)

        if
            let candidateDate = calendar.occurrenceDate(in: candidateMonth, day: plan.dayOfMonth),
            candidateDate < referenceDate
        {
            candidateMonth = calendar.date(byAdding: .month, value: 1, to: candidateMonth) ?? candidateMonth
        }

        if let endMonth = plan.endMonth.map({ calendar.startOfMonth(for: $0) }), candidateMonth > endMonth {
            return nil
        }

        return calendar.occurrenceDate(in: candidateMonth, day: plan.dayOfMonth)
    }
}
