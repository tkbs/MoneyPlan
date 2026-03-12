import Foundation

extension Sequence where Element == TransactionPlan {
    /// 指定入出金種別の合計金額を返す。
    func totalAmount(for flowType: FlowType) -> Int {
        reduce(0) { partialResult, plan in
            guard plan.flowType == flowType else {
                return partialResult
            }
            return partialResult + plan.amount
        }
    }
}
