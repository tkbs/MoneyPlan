import Foundation

extension String {
    /// フォーム入力や検索条件で使う前後空白を除去する。
    var moneyPlanTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
