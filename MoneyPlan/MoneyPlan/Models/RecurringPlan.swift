import Foundation
import SwiftData

@Model
final class RecurringPlan {
    @Attribute(.unique) var id: UUID
    var flowTypeRawValue: String
    var name: String
    var amount: Int
    var dayOfMonth: Int
    var startMonth: Date
    var endMonth: Date?
    var isActive: Bool
    var note: String
    var createdAt: Date
    var updatedAt: Date

    var flowType: FlowType {
        get { FlowType(rawValue: flowTypeRawValue) ?? .expense }
        set { flowTypeRawValue = newValue.rawValue }
    }

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
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.flowTypeRawValue = flowType.rawValue
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
