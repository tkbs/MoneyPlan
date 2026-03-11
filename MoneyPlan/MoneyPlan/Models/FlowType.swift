import Foundation

enum FlowType: String, Codable, CaseIterable, Sendable {
    case income
    case expense

    var displayName: String {
        switch self {
        case .income:
            "入金"
        case .expense:
            "出金"
        }
    }

    var signedMultiplier: Int {
        switch self {
        case .income:
            1
        case .expense:
            -1
        }
    }
}
