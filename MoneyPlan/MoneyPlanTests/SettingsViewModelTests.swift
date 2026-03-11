import Foundation
import Testing
@testable import MoneyPlan

@MainActor
struct SettingsViewModelTests {
    /// 数値入力と閾値の下限を検証できる。
    @Test func validatesNumericFields() {
        let viewModel = SettingsViewModel()
        viewModel.initialBalanceText = "abc"
        viewModel.warningBalanceThresholdText = "-1"

        let input = viewModel.makeInput()

        #expect(input == nil)
        #expect(viewModel.validationMessage == "入力内容を確認してください")
        #expect(viewModel.fieldErrors[.initialBalance] == "初期残高を数値で入力してください")
        #expect(viewModel.fieldErrors[.warningBalanceThreshold] == "警告閾値は 0 円以上で入力してください")
    }

    /// 設定値読込時にフォームへ文字列変換して反映する。
    @Test func loadsSettingValues() {
        let viewModel = SettingsViewModel()
        let setting = AppSetting(initialBalance: -5_000, warningBalanceThreshold: 10_000)

        viewModel.load(setting: setting)

        #expect(viewModel.initialBalanceText == "-5000")
        #expect(viewModel.warningBalanceThresholdText == "10000")
    }

    /// 保存入力生成時に前後空白を除去する。
    @Test func trimsAndConvertsInputValues() {
        let viewModel = SettingsViewModel()
        viewModel.initialBalanceText = " -2000 "
        viewModel.warningBalanceThresholdText = " 3000 "

        let input = viewModel.makeInput()

        #expect(input?.initialBalance == -2000)
        #expect(input?.warningBalanceThreshold == 3000)
    }
}
