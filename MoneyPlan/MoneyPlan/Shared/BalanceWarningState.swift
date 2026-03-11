import SwiftUI

enum BalanceWarningState: Equatable {
    case none
    case warning
    case negative

    /// 残高と閾値から警告状態を判定する。
    static func from(balance: Int, warningThreshold: Int) -> BalanceWarningState {
        if balance < 0 {
            return .negative
        }
        if balance <= warningThreshold {
            return .warning
        }
        return .none
    }

    var tintColor: Color {
        switch self {
        case .none:
            .secondary
        case .warning:
            .orange
        case .negative:
            .red
        }
    }
}
