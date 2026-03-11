import SwiftUI

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
    private func bootstrapIfNeeded() throws {
        guard didBootstrap == false else {
            return
        }

        do {
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
