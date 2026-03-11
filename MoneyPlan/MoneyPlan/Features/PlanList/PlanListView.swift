import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(AppNavigationState.self) private var navigationState
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\TransactionPlan.date, order: .forward),
            SortDescriptor(\TransactionPlan.sortOrder, order: .forward),
            SortDescriptor(\TransactionPlan.createdAt, order: .forward),
            SortDescriptor(\TransactionPlan.id, order: .forward),
        ]
    ) private var plans: [TransactionPlan]
    @Query(sort: [SortDescriptor(\AppSetting.createdAt, order: .forward)]) private var settings: [AppSetting]
    @Query(
        sort: [
            SortDescriptor(\RecurringPlan.dayOfMonth, order: .forward),
            SortDescriptor(\RecurringPlan.createdAt, order: .forward),
        ]
    ) private var recurringPlans: [RecurringPlan]
    @State private var viewModel = PlanListViewModel()
    @State private var isShowingMonthlySummary = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                planListContent(using: proxy)
            }
        }
    }

    /// 予定更新の再読込判定に使うトークン。
    private var planReloadToken: [Date] {
        plans.map(\.updatedAt)
    }

    /// 削除対象有無を確認ダイアログ表示へ変換する。
    private var deletingPlanBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deletingPlan != nil },
            set: { isPresented in
                if isPresented == false {
                    viewModel.deletingPlan = nil
                }
            }
        )
    }

    /// 表示条件に応じて一覧セクションを再構築する。
    private func reloadSections() {
        viewModel.reload(
            plans: plans,
            initialBalance: settings.first?.initialBalance ?? 0,
            warningThreshold: settings.first?.warningBalanceThreshold ?? 0
        )
    }

    /// 選択中の予定を削除する。
    private func deleteSelectedPlan() {
        guard let deletingPlan = viewModel.deletingPlan else {
            return
        }

        do {
            let repository = PlanRepository(modelContext: modelContext)
            try repository.delete(deletingPlan)
            viewModel.deletingPlan = nil
        } catch {
            viewModel.deletingPlan = nil
        }
    }

    /// 予定一覧画面の主要コンテンツを構築する。
    @ViewBuilder
    private func planListContent(using proxy: ScrollViewProxy) -> some View {
        List {
            sectionList
            emptyStateView
        }
        .navigationTitle("予定")
        .toolbar {
            planListToolbar
        }
        .searchable(text: $viewModel.searchText, prompt: "名称で検索")
        .sheet(isPresented: $viewModel.isShowingEditor) {
            PlanEditorView(
                plan: viewModel.editingPlan,
                recurringPlans: recurringPlans
            )
        }
        .sheet(isPresented: $isShowingMonthlySummary) {
            MonthlySummaryView(initialMonth: viewModel.targetMonth)
        }
        .confirmationDialog(
            "この予定を削除します。",
            isPresented: deletingPlanBinding,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                deleteSelectedPlan()
            }
            Button("キャンセル", role: .cancel) {
                viewModel.deletingPlan = nil
            }
        }
        .onAppear {
            reloadSections()
        }
        .onChange(of: planReloadToken) { _, _ in
            reloadSections()
        }
        .onChange(of: settings.first?.initialBalance) { _, _ in
            reloadSections()
        }
        .onChange(of: settings.first?.warningBalanceThreshold) { _, _ in
            reloadSections()
        }
        .onChange(of: viewModel.targetMonth) { _, _ in
            reloadSections()
        }
        .onChange(of: viewModel.searchText) { _, _ in
            reloadSections()
        }
        .onChange(of: navigationState.planListFocusRequest?.id) { _, _ in
            handleFocusRequest(using: proxy)
        }
        .task {
            handleFocusRequest(using: proxy)
        }
    }

    /// 日付セクション付きの予定一覧を返す。
    @ViewBuilder
    private var sectionList: some View {
        ForEach(viewModel.sections) { section in
            Section {
                ForEach(section.rows) { row in
                    rowButton(for: row)
                }
            } header: {
                PlanListSectionHeaderView(section: section)
                    .id(section.date)
            }
        }
    }

    /// 空状態表示を返す。
    @ViewBuilder
    private var emptyStateView: some View {
        if viewModel.sections.isEmpty {
            ContentUnavailableView(
                "予定がありません",
                systemImage: "list.bullet.rectangle",
                description: Text("対象月に表示できる予定がありません。")
            )
        }
    }

    /// 一覧画面のツールバー構成を返す。
    @ToolbarContentBuilder
    private var planListToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            MonthSwitcherView(
                targetMonth: viewModel.targetMonth,
                onPrevious: viewModel.showPreviousMonth,
                onNext: viewModel.showNextMonth
            )
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isShowingMonthlySummary = true
            } label: {
                Image(systemName: "calendar")
            }
            .accessibilityIdentifier("plan-list-monthly-summary-button")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.presentCreate()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityIdentifier("plan-list-add-button")
        }
    }

    /// 予定行ボタンを返す。
    @ViewBuilder
    private func rowButton(for row: PlanListRowModel) -> some View {
        Button {
            if let plan = plans.first(where: { $0.id == row.planID }) {
                viewModel.presentEdit(for: plan)
            }
        } label: {
            PlanListRowView(row: row)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("plan-row-\(row.name)")
        .swipeActions {
            Button("削除", role: .destructive) {
                if let plan = plans.first(where: { $0.id == row.planID }) {
                    viewModel.deletingPlan = plan
                }
            }
        }
    }

    /// 外部画面から受けた対象日へ移動し、対応セクションへスクロールする。
    private func handleFocusRequest(using proxy: ScrollViewProxy) {
        guard let request = navigationState.planListFocusRequest else {
            return
        }

        viewModel.focus(on: request.date)
        reloadSections()

        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(request.date, anchor: .top)
            }
            navigationState.consumePlanListFocusRequest()
        }
    }
}

private struct PlanListRowView: View {
    let row: PlanListRowModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(row.flowType == .income ? Color.green : Color.red)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(row.name)
                        .font(.headline)
                    if row.isAutoGenerated {
                        Text("自動")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if row.memo.isEmpty == false {
                    Text(row.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text("残高 \(row.displayRunningBalance)")
                    .font(.caption)
                    .foregroundStyle(row.warningState.tintColor)
            }

            Spacer()

            Text(row.displayAmount)
                .font(.headline)
                .foregroundStyle(row.flowType == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

private struct PlanListSectionHeaderView: View {
    let section: PlanListSection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                .font(.headline)

            Text("入金 \(CurrencyFormatter.string(from: section.dailyIncomeTotal)) / 出金 \(CurrencyFormatter.string(from: section.dailyExpenseTotal))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MonthSwitcherView: View {
    let targetMonth: Date
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
            }
            .accessibilityIdentifier("plan-list-previous-month-button")
            Text(targetMonth, format: Date.FormatStyle().year().month(.wide))
                .font(.headline)
                .frame(minWidth: 120)
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
            .accessibilityIdentifier("plan-list-next-month-button")
        }
    }
}

#Preview {
    PlanListView()
        .environment(AppNavigationState())
}
