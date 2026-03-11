import Foundation

struct RecurringPlanRowModel: Identifiable {
    let planID: UUID
    let name: String
    let displayAmount: String
    let note: String
    let dayDescription: String
    let nextOccurrenceDescription: String
    let isActive: Bool
    let flowType: FlowType

    var id: UUID { planID }
}
