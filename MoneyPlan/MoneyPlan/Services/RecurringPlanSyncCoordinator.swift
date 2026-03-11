import Foundation
import SwiftData

@MainActor
struct RecurringPlanSyncCoordinator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// 有効な定期予定を基準に将来自動生成予定を再同期する。
    func sync(in modelContext: ModelContext, generationStartMonth: Date = .now) throws {
        let repository = RecurringPlanRepository(modelContext: modelContext, calendar: calendar)
        let generator = RecurringPlanGenerator(calendar: calendar)
        let activePlans = try repository.fetchActivePlans()

        try generator.syncFuturePlans(
            templates: activePlans,
            in: modelContext,
            generationStartMonth: generationStartMonth,
            generationMonthCount: MoneyPlanConstants.recurringGenerationMonthCount
        )
    }
}
