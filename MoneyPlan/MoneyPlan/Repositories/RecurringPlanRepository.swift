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
    func save(input: RecurringPlanEditorInput, original: RecurringPlan? = nil) throws -> RecurringPlan {
        let plan = original ?? RecurringPlan(
            flowType: input.flowType,
            name: input.name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: input.amount,
            dayOfMonth: input.dayOfMonth,
            startMonth: calendar.startOfMonth(for: input.startMonth),
            endMonth: input.endMonth.map { calendar.startOfMonth(for: $0) },
            isActive: input.isActive,
            note: input.note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if original == nil {
            modelContext.insert(plan)
        }

        plan.flowType = input.flowType
        plan.name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.amount = input.amount
        plan.dayOfMonth = input.dayOfMonth
        plan.startMonth = calendar.startOfMonth(for: input.startMonth)
        plan.endMonth = input.endMonth.map { calendar.startOfMonth(for: $0) }
        plan.isActive = input.isActive
        plan.note = input.note.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.updatedAt = .now

        try modelContext.save()
        return plan
    }

    /// 指定定期予定を削除する。
    func delete(_ plan: RecurringPlan) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }
}
