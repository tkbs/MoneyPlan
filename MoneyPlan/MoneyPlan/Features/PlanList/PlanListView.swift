import SwiftUI
import SwiftData

struct PlanListView: View {
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
            List {
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            Button {
                                if let plan = plans.first(where: { $0.id == row.planID }) {
                                    viewModel.presentEdit(for: plan)
                                }
                            } label: {
                                PlanListRowView(row: row)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("削除", role: .destructive) {
                                    if let plan = plans.first(where: { $0.id == row.planID }) {
                                        viewModel.deletingPlan = plan
                                    }
                                }
                            }
                        }
                    } header: {
                        PlanListSectionHeaderView(section: section)
                    }
                }

                if viewModel.sections.isEmpty {
                    ContentUnavailableView(
                        "予定がありません",
                        systemImage: "list.bullet.rectangle",
                        description: Text("対象月に表示できる予定がありません。")
                    )
                }
            }
            .navigationTitle("予定")
            .toolbar {
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
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentCreate()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
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
            Text(targetMonth, format: Date.FormatStyle().year().month(.wide))
                .font(.headline)
                .frame(minWidth: 120)
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
        }
    }
}

#Preview {
    PlanListView()
}
