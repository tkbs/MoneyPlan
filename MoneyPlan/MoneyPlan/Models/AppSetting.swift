import Foundation
import SwiftData

@Model
final class AppSetting {
    @Attribute(.unique) var id: UUID
    var initialBalance: Int
    var warningBalanceThreshold: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        initialBalance: Int = 0,
        warningBalanceThreshold: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.initialBalance = initialBalance
        self.warningBalanceThreshold = warningBalanceThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
