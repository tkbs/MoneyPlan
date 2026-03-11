import Foundation
import Testing
@testable import MoneyPlan

@MainActor
struct RecurringPlanListViewModelTests {
    private let calendar = Calendar(identifier: .gregorian)

    /// 次回予定日を日本語表記で表示する。
    @Test func formatsNextOccurrenceInJapanese() {
        let viewModel = RecurringPlanListViewModel(calendar: calendar)
        let referenceDate = makeDate(month: 3, day: 11)
        let plan = RecurringPlan(
            flowType: .expense,
            name: "家賃",
            amount: 80_000,
            dayOfMonth: 25,
            startMonth: makeDate(month: 1, day: 1)
        )

        viewModel.reload(plans: [plan], referenceDate: referenceDate)

        #expect(viewModel.plans.first?.nextOccurrenceDescription == "次回 2026年3月25日")
    }

    /// テスト用の日付を作る。
    private func makeDate(month: Int, day: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: 2026,
            month: month,
            day: day
        )
        return components.date ?? .distantPast
    }
}
