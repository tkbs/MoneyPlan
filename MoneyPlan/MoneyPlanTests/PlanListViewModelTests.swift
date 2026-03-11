import Foundation
import Testing
@testable import MoneyPlan

struct PlanListViewModelTests {
    private let calendar = Calendar(identifier: .gregorian)

    /// 対象日フォーカス時に対象月へ移動し、検索条件を解除できる。
    @Test func focusesTargetDateAndClearsSearchText() {
        let viewModel = PlanListViewModel(
            targetMonth: makeDate(month: 3, day: 1),
            calendar: calendar
        )
        viewModel.searchText = "家賃"

        viewModel.focus(on: makeDate(month: 5, day: 21))

        #expect(viewModel.targetMonth == makeDate(month: 5, day: 1))
        #expect(viewModel.searchText.isEmpty)
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
