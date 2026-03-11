import Foundation
import SwiftData

@MainActor
struct SettingRepository {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 設定を取得し、未作成なら初期レコードを作る。
    @discardableResult
    func fetchOrCreate() throws -> AppSetting {
        let settings = try fetchAll()

        if let primarySetting = settings.first {
            if settings.count > 1 {
                try normalizeIfNeeded(using: settings)
            }
            return primarySetting
        }

        let setting = AppSetting()
        modelContext.insert(setting)
        try modelContext.save()
        return setting
    }

    /// 設定値を更新する。
    func update(initialBalance: Int, warningBalanceThreshold: Int) throws {
        let setting = try fetchOrCreate()
        setting.initialBalance = initialBalance
        setting.warningBalanceThreshold = warningBalanceThreshold
        setting.updatedAt = .now
        try modelContext.save()
    }

    /// 設定重複を解消して 1 件に正規化する。
    func normalizeIfNeeded() throws {
        try normalizeIfNeeded(using: fetchAll())
    }

    /// 既存設定を作成順で取得する。
    private func fetchAll() throws -> [AppSetting] {
        let descriptor = FetchDescriptor<AppSetting>(
            sortBy: [
                SortDescriptor(\AppSetting.createdAt, order: .forward),
                SortDescriptor(\AppSetting.id, order: .forward),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 既存設定一覧から余剰レコードを削除する。
    private func normalizeIfNeeded(using settings: [AppSetting]) throws {
        guard settings.count > 1 else { return }

        for duplicatedSetting in settings.dropFirst() {
            modelContext.delete(duplicatedSetting)
        }

        try modelContext.save()
    }
}
