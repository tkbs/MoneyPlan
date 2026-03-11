import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var navigationState = AppNavigationState()
    @State private var bootstrapErrorMessage: String?
    @State private var didBootstrap = false

    var body: some View {
        TabView(selection: $navigationState.selectedTab) {
            DashboardView()
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            PlanListView()
                .tag(AppTab.planList)
                .tabItem {
                    Label("予定", systemImage: "list.bullet")
                }

            RecurringPlanListView()
                .tag(AppTab.recurringPlanList)
                .tabItem {
                    Label("定期", systemImage: "repeat")
                }

            SettingsView()
                .tag(AppTab.settings)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .environment(navigationState)
        .task {
            try? bootstrapIfNeeded()
        }
        .alert("初期化エラー", isPresented: bootstrapErrorBinding) {
            Button("閉じる", role: .cancel) {
                bootstrapErrorMessage = nil
            }
        } message: {
            Text(bootstrapErrorMessage ?? "")
        }
    }

    /// 初回表示時の設定生成と定期予定展開を行う。
    @MainActor
    private func bootstrapIfNeeded() throws {
        guard didBootstrap == false else {
            return
        }

        do {
            if MoneyPlanUITestSupport.isEnabled {
                try MoneyPlanUITestSupport.prepareData(in: modelContext)
            }

            let settingRepository = SettingRepository(modelContext: modelContext)
            let recurringPlanSyncCoordinator = RecurringPlanSyncCoordinator()

            _ = try settingRepository.fetchOrCreate()
            try settingRepository.normalizeIfNeeded()
            try recurringPlanSyncCoordinator.sync(in: modelContext)

            didBootstrap = true
        } catch {
            bootstrapErrorMessage = error.localizedDescription
        }
    }

    /// エラーメッセージ有無をアラート表示状態へ変換する。
    private var bootstrapErrorBinding: Binding<Bool> {
        Binding(
            get: { bootstrapErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    bootstrapErrorMessage = nil
                }
            }
        )
    }
}

private enum MoneyPlanUITestSupport {
    /// UI テスト専用起動かを判定する。
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    /// テストごとの初期データ種別を返す。
    static var scenario: Scenario {
        Scenario(
            rawValue: ProcessInfo.processInfo.environment["MONEYPLAN_UI_TEST_SCENARIO"] ?? ""
        ) ?? .empty
    }

    /// テスト開始前に永続データをクリアし、シナリオ初期値を投入する。
    @MainActor
    static func prepareData(in modelContext: ModelContext, calendar: Calendar = .current) throws {
        try deleteAll(TransactionPlan.self, in: modelContext)
        try deleteAll(RecurringPlan.self, in: modelContext)
        try deleteAll(AppSetting.self, in: modelContext)

        modelContext.insert(
            AppSetting(
                initialBalance: 100_000,
                warningBalanceThreshold: 30_000
            )
        )

        switch scenario {
        case .empty:
            break
        case .existingPlan:
            modelContext.insert(
                TransactionPlan(
                    date: calendar.startOfDay(
                        for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
                    ),
                    flowType: .expense,
                    name: "UI既存予定",
                    amount: 40_000,
                    memo: "編集削除確認用",
                    sortOrder: 0
                )
            )
        }

        try modelContext.save()
    }

    /// 指定モデルを全削除する。
    @MainActor
    private static func deleteAll<T: PersistentModel>(_ modelType: T.Type, in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<T>()
        for model in try modelContext.fetch(descriptor) {
            modelContext.delete(model)
        }
    }

    enum Scenario: String {
        case empty
        case existingPlan
    }
}
