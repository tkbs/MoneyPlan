import Foundation

enum MoneyPlanConstants {
    /// 定期予定を自動生成する月数。
    static let recurringGenerationMonthCount = 12

    /// ダッシュボードに表示する直近予定件数。
    static let dashboardUpcomingPlanLimit = 5

    /// ダッシュボードの直近グラフ対象日数。
    static let dashboardGraphDayCount = 30

    /// 定期予定日の最小値。
    static let minimumRecurringDay = 1

    /// 定期予定日の最大値。
    static let maximumRecurringDay = 28

    /// 同日内表示順の初期値。
    static let defaultSortOrder = 0
}
