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
    var planListCreateRequestID: UUID?
    var recurringPlanListCreateRequestID: UUID?

    /// 予定一覧タブを開き、対象日へのフォーカス要求を登録する。
    func openPlanList(on date: Date, calendar: Calendar = .current) {
        selectedTab = .planList
        planListFocusRequest = PlanListFocusRequest(date: calendar.startOfDay(for: date))
    }

    /// 予定一覧で処理済みのフォーカス要求を破棄する。
    func consumePlanListFocusRequest() {
        planListFocusRequest = nil
    }

    /// 予定一覧タブを開き、新規予定作成の要求を登録する。
    func openPlanListForCreation() {
        selectedTab = .planList
        planListCreateRequestID = UUID()
    }

    /// 予定一覧で処理済みの新規予定作成要求を破棄する。
    func consumePlanListCreateRequest() {
        planListCreateRequestID = nil
    }

    /// 定期予定タブを開き、新規定期予定作成の要求を登録する。
    func openRecurringPlanListForCreation() {
        selectedTab = .recurringPlanList
        recurringPlanListCreateRequestID = UUID()
    }

    /// 定期予定一覧で処理済みの新規作成要求を破棄する。
    func consumeRecurringPlanListCreateRequest() {
        recurringPlanListCreateRequestID = nil
    }
}
