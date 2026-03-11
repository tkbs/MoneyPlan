import Foundation
import Testing
@testable import MoneyPlan

@MainActor
struct RecurringPlanEditorViewModelTests {
    /// 必須項目と期間条件を検証できる。
    @Test func validatesRequiredFieldsAndMonthRange() {
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = RecurringPlanEditorViewModel(plan: nil, calendar: calendar)
        viewModel.name = " "
        viewModel.amountText = "0"
        viewModel.dayOfMonth = 31
        viewModel.hasEndMonth = true
        viewModel.startMonth = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? .now
        viewModel.endMonth = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? .now

        let input = viewModel.makeInput(calendar: calendar)

        #expect(input == nil)
        #expect(viewModel.validationMessage == "入力内容を確認してください")
        #expect(viewModel.fieldErrors[.name] == "名称を入力してください")
        #expect(viewModel.fieldErrors[.amount] == "金額は 1 円以上で入力してください")
        #expect(viewModel.fieldErrors[.dayOfMonth] == "発生日は 1 日から 28 日で指定してください")
        #expect(viewModel.fieldErrors[.endMonth] == "終了月は開始月以降を指定してください")
    }

    /// 保存入力生成時に月初正規化と空白除去を行う。
    @Test func normalizesInputValues() {
        let calendar = Calendar(identifier: .gregorian)
        let viewModel = RecurringPlanEditorViewModel(plan: nil, calendar: calendar)
        viewModel.flowType = .income
        viewModel.name = " 給与 "
        viewModel.amountText = "250000"
        viewModel.dayOfMonth = 25
        viewModel.startMonth = calendar.date(from: DateComponents(year: 2026, month: 4, day: 20)) ?? .now
        viewModel.hasEndMonth = true
        viewModel.endMonth = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31)) ?? .now
        viewModel.isActive = false
        viewModel.note = " メモ "

        let input = viewModel.makeInput(calendar: calendar)

        #expect(input?.flowType == .income)
        #expect(input?.name == "給与")
        #expect(input?.amount == 250000)
        #expect(input?.dayOfMonth == 25)
        #expect(input?.startMonth == calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        #expect(input?.endMonth == calendar.date(from: DateComponents(year: 2026, month: 12, day: 1)))
        #expect(input?.isActive == false)
        #expect(input?.note == "メモ")
    }
}
