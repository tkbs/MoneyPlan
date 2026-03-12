import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SettingsViewModel {
    var initialBalanceText = ""
    var warningBalanceThresholdText = ""
    var validationMessage: String?
    var fieldErrors: [Field: String] = [:]
    var saveErrorMessage: String?

    private var loadedSettingID: UUID?

    enum Field {
        case initialBalance
        case warningBalanceThreshold
    }

    /// 表示中の設定値をフォームへ読み込む。
    func load(setting: AppSetting) {
        guard loadedSettingID != setting.id else {
            return
        }

        initialBalanceText = String(setting.initialBalance)
        warningBalanceThresholdText = String(setting.warningBalanceThreshold)
        loadedSettingID = setting.id
        validationMessage = nil
        fieldErrors = [:]
        saveErrorMessage = nil
    }

    /// 入力値を検証して保存用タプルへ変換する。
    func makeInput() -> (initialBalance: Int, warningBalanceThreshold: Int)? {
        validationMessage = nil
        fieldErrors = [:]

        let trimmedInitialBalanceText = initialBalanceText.moneyPlanTrimmed
        let trimmedWarningBalanceThresholdText = warningBalanceThresholdText.moneyPlanTrimmed

        let initialBalance = Int(trimmedInitialBalanceText)
        if initialBalance == nil {
            fieldErrors[.initialBalance] = "初期残高を数値で入力してください"
        }

        let warningBalanceThreshold = Int(trimmedWarningBalanceThresholdText)
        if warningBalanceThreshold == nil || (warningBalanceThreshold ?? -1) < 0 {
            fieldErrors[.warningBalanceThreshold] = "警告閾値は 0 円以上で入力してください"
        }

        guard fieldErrors.isEmpty else {
            validationMessage = "入力内容を確認してください"
            return nil
        }

        return (
            initialBalance: initialBalance ?? 0,
            warningBalanceThreshold: warningBalanceThreshold ?? 0
        )
    }

    /// 設定を保存する。
    func save(using modelContext: ModelContext) throws {
        saveErrorMessage = nil
        guard let input = makeInput() else {
            return
        }

        do {
            let repository = SettingRepository(modelContext: modelContext)
            try repository.update(
                initialBalance: input.initialBalance,
                warningBalanceThreshold: input.warningBalanceThreshold
            )
        } catch {
            saveErrorMessage = error.localizedDescription
            throw error
        }
    }
}
