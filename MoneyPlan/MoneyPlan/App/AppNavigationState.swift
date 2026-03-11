import Foundation
import Observation

enum AppTab: Hashable {
    case dashboard
    case planList
    case recurringPlanList
    case settings
}

struct PlanListFocusRequest: Equatable, Identifiable {
    let id = UUID()
    let date: Date
}

@Observable
final class AppNavigationState {
    var selectedTab: AppTab = .dashboard
    var planListFocusRequest: PlanListFocusRequest?

    /// 予定一覧タブを開き、対象日へのフォーカス要求を登録する。
    func openPlanList(on date: Date, calendar: Calendar = .current) {
        selectedTab = .planList
        planListFocusRequest = PlanListFocusRequest(date: calendar.startOfDay(for: date))
    }

    /// 予定一覧で処理済みのフォーカス要求を破棄する。
    func consumePlanListFocusRequest() {
        planListFocusRequest = nil
    }
}
