import Foundation
import Testing
@testable import MoneyPlan

@MainActor
struct PlanEditorViewModelTests {
    /// 定期予定選択で入力初期値を反映できる。
    @Test func appliesRecurringPlanDefaults() {
        let recurringPlan = RecurringPlan(
            flowType: .income,
            name: "給与",
            amount: 250_000,
            dayOfMonth: 25,
            startMonth: .now
        )
        let viewModel = PlanEditorViewModel(plan: nil, recurringPlans: [recurringPlan])

        viewModel.selectedRecurringPlanID = recurringPlan.id
        viewModel.applySelectedRecurringPlan()

        #expect(viewModel.flowType == .income)
        #expect(viewModel.name == "給与")
        #expect(viewModel.amountText == "250000")
    }

    /// 必須項目と数値入力を検証できる。
    @Test func validatesRequiredFields() {
        let viewModel = PlanEditorViewModel(plan: nil, recurringPlans: [])
        viewModel.name = " "
        viewModel.amountText = "0"
        viewModel.sortOrderText = "-1"

        let input = viewModel.makeInput()

        #expect(input == nil)
        #expect(viewModel.validationMessage == "入力内容を確認してください")
        #expect(viewModel.fieldErrors[.name] == "名称を入力してください")
        #expect(viewModel.fieldErrors[.amount] == "金額は 1 円以上で入力してください")
        #expect(viewModel.fieldErrors[.sortOrder] == "表示順は 0 以上で入力してください")
    }
}
