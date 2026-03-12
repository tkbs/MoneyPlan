import Foundation
import SwiftData

struct RecurringPlanEditorInput {
    let flowType: FlowType
    let name: String
    let amount: Int
    let dayOfMonth: Int
    let startMonth: Date
    let endMonth: Date?
    let isActive: Bool
    let note: String
}

@MainActor
struct RecurringPlanRepository {
    let modelContext: ModelContext
    let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    /// 全定期予定を一覧順で取得する。
    func fetchAll() throws -> [RecurringPlan] {
        let descriptor = FetchDescriptor<RecurringPlan>(
            sortBy: [
                SortDescriptor(\RecurringPlan.dayOfMonth, order: .forward),
                SortDescriptor(\RecurringPlan.createdAt, order: .forward),
                SortDescriptor(\RecurringPlan.id, order: .forward),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 有効な定期予定のみを取得する。
    func fetchActivePlans() throws -> [RecurringPlan] {
        let descriptor = FetchDescriptor<RecurringPlan>(
            predicate: #Predicate<RecurringPlan> { plan in
                plan.isActive
            },
            sortBy: [
                SortDescriptor(\RecurringPlan.dayOfMonth, order: .forward),
                SortDescriptor(\RecurringPlan.createdAt, order: .forward),
                SortDescriptor(\RecurringPlan.id, order: .forward),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 編集入力から定期予定を保存する。
    @discardableResult
    func save(
        input: RecurringPlanEditorInput,
        original: RecurringPlan? = nil,
        persistChanges: Bool = true
    ) throws -> RecurringPlan {
        let normalizedInput = normalize(input)
        let plan = original ?? RecurringPlan(
            flowType: normalizedInput.flowType,
            name: normalizedInput.name,
            amount: normalizedInput.amount,
            dayOfMonth: normalizedInput.dayOfMonth,
            startMonth: normalizedInput.startMonth,
            endMonth: normalizedInput.endMonth,
            isActive: normalizedInput.isActive,
            note: normalizedInput.note
        )

        if original == nil {
            modelContext.insert(plan)
        }

        apply(normalizedInput, to: plan)
        plan.updatedAt = .now

        if persistChanges {
            try modelContext.save()
        }
        return plan
    }

    /// 指定定期予定を削除する。
    func delete(_ plan: RecurringPlan, persistChanges: Bool = true) throws {
        modelContext.delete(plan)
        if persistChanges {
            try modelContext.save()
        }
    }

    /// 保存前の定期予定入力を月初・空白除去込みで正規化する。
    private func normalize(_ input: RecurringPlanEditorInput) -> NormalizedRecurringPlanInput {
        NormalizedRecurringPlanInput(
            flowType: input.flowType,
            name: input.name.moneyPlanTrimmed,
            amount: input.amount,
            dayOfMonth: input.dayOfMonth,
            startMonth: calendar.startOfMonth(for: input.startMonth),
            endMonth: input.endMonth.map { calendar.startOfMonth(for: $0) },
            isActive: input.isActive,
            note: input.note.moneyPlanTrimmed
        )
    }

    /// 正規化済み入力を定期予定モデルへ反映する。
    private func apply(_ input: NormalizedRecurringPlanInput, to plan: RecurringPlan) {
        plan.flowType = input.flowType
        plan.name = input.name
        plan.amount = input.amount
        plan.dayOfMonth = input.dayOfMonth
        plan.startMonth = input.startMonth
        plan.endMonth = input.endMonth
        plan.isActive = input.isActive
        plan.note = input.note
    }
}

private struct NormalizedRecurringPlanInput {
    let flowType: FlowType
    let name: String
    let amount: Int
    let dayOfMonth: Int
    let startMonth: Date
    let endMonth: Date?
    let isActive: Bool
    let note: String
}
