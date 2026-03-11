import Foundation
import SwiftData

@Model
final class RecurringPlan {
    @Attribute(.unique) var id: UUID
    var flowType: FlowType
    var name: String
    var amount: Int
    var dayOfMonth: Int
    var startMonth: Date
    var endMonth: Date?
    var isActive: Bool
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    var signedAmount: Int {
        amount * flowType.signedMultiplier
    }

    init(
        id: UUID = UUID(),
        flowType: FlowType,
        name: String,
        amount: Int,
        dayOfMonth: Int,
        startMonth: Date,
        endMonth: Date? = nil,
        isActive: Bool = true,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.flowType = flowType
        self.name = name
        self.amount = amount
        self.dayOfMonth = dayOfMonth
        self.startMonth = startMonth
        self.endMonth = endMonth
        self.isActive = isActive
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
