import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class RecurringPlanEditorViewModel {
    let originalPlan: RecurringPlan?

    var flowType: FlowType
    var name: String
    var amountText: String
    var dayOfMonth: Int
    var startMonth: Date
    var hasEndMonth: Bool
    var endMonth: Date
    var isActive: Bool
    var note: String
    var validationMessage: String?
    var fieldErrors: [Field: String] = [:]
    var saveErrorMessage: String?

    enum Field {
        case name
        case amount
        case dayOfMonth
        case endMonth
    }

    init(plan: RecurringPlan?, calendar: Calendar = .current) {
        self.originalPlan = plan
        self.flowType = plan?.flowType ?? .expense
        self.name = plan?.name ?? ""
        self.amountText = plan.map { String($0.amount) } ?? ""
        self.dayOfMonth = plan?.dayOfMonth ?? MoneyPlanConstants.minimumRecurringDay
        self.startMonth = calendar.startOfMonth(for: plan?.startMonth ?? .now)
        self.hasEndMonth = plan?.endMonth != nil
        self.endMonth = calendar.startOfMonth(for: plan?.endMonth ?? plan?.startMonth ?? .now)
        self.isActive = plan?.isActive ?? true
        self.note = plan?.note ?? ""
    }

    var navigationTitle: String {
        originalPlan == nil ? "定期予定を追加" : "定期予定を編集"
    }

    var isEditing: Bool {
        originalPlan != nil
    }

    /// 入力内容を検証して保存入力へ変換する。
    func makeInput(calendar: Calendar = .current) -> RecurringPlanEditorInput? {
        validationMessage = nil
        fieldErrors = [:]

        let trimmedName = name.moneyPlanTrimmed
        let trimmedNote = note.moneyPlanTrimmed
        let trimmedAmountText = amountText.moneyPlanTrimmed
        let amount = Int(trimmedAmountText)
        let normalizedStartMonth = calendar.startOfMonth(for: startMonth)
        let normalizedEndMonth = hasEndMonth ? calendar.startOfMonth(for: endMonth) : nil

        if trimmedName.isEmpty {
            fieldErrors[.name] = "名称を入力してください"
        }

        if amount == nil || (amount ?? 0) < 1 {
            fieldErrors[.amount] = "金額は 1 円以上で入力してください"
        }

        if (MoneyPlanConstants.minimumRecurringDay...MoneyPlanConstants.maximumRecurringDay).contains(dayOfMonth) == false {
            fieldErrors[.dayOfMonth] = "発生日は 1 日から 28 日で指定してください"
        }

        if let normalizedEndMonth, normalizedEndMonth < normalizedStartMonth {
            fieldErrors[.endMonth] = "終了月は開始月以降を指定してください"
        }

        guard fieldErrors.isEmpty else {
            validationMessage = "入力内容を確認してください"
            return nil
        }

        return RecurringPlanEditorInput(
            flowType: flowType,
            name: trimmedName,
            amount: amount ?? 0,
            dayOfMonth: dayOfMonth,
            startMonth: normalizedStartMonth,
            endMonth: normalizedEndMonth,
            isActive: isActive,
            note: trimmedNote
        )
    }

    /// 定期予定を保存し、将来自動生成予定も再同期する。
    func save(using modelContext: ModelContext) throws {
        saveErrorMessage = nil
        guard let input = makeInput() else {
            return
        }

        let repository = RecurringPlanRepository(modelContext: modelContext)
        let syncCoordinator = RecurringPlanSyncCoordinator()

        do {
            _ = try repository.save(input: input, original: originalPlan, persistChanges: false)
            try syncCoordinator.sync(in: modelContext)
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            throw error
        }
    }

    /// 定期予定を削除し、将来自動生成予定も再同期する。
    func delete(using modelContext: ModelContext) throws {
        guard let originalPlan else {
            return
        }

        let repository = RecurringPlanRepository(modelContext: modelContext)
        let syncCoordinator = RecurringPlanSyncCoordinator()

        do {
            try repository.delete(originalPlan, persistChanges: false)
            try syncCoordinator.sync(in: modelContext)
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            throw error
        }
    }
}
