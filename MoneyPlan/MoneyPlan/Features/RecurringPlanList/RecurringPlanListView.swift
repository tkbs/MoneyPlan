import SwiftUI
import SwiftData

struct RecurringPlanListView: View {
    @Environment(AppNavigationState.self) private var navigationState
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\RecurringPlan.dayOfMonth, order: .forward),
            SortDescriptor(\RecurringPlan.createdAt, order: .forward),
            SortDescriptor(\RecurringPlan.id, order: .forward),
        ]
    ) private var recurringPlans: [RecurringPlan]
    @State private var viewModel = RecurringPlanListViewModel()
    @State private var actionErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.plans) { row in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            if let plan = recurringPlans.first(where: { $0.id == row.planID }) {
                                viewModel.presentEdit(for: plan)
                            }
                        } label: {
                            RecurringPlanRowView(row: row)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("recurring-plan-row-\(row.name)")

                        Toggle("", isOn: isActiveBinding(for: row.planID))
                            .labelsHidden()
                            .accessibilityLabel("\(row.name)の有効状態")
                            .accessibilityIdentifier("recurring-plan-toggle-\(row.name)")
                    }
                    .swipeActions {
                        Button("削除", role: .destructive) {
                            viewModel.deletingPlan = recurringPlans.first(where: { $0.id == row.planID })
                        }
                    }
                }

                if viewModel.plans.isEmpty {
                    ContentUnavailableView(
                        "定期予定がありません",
                        systemImage: "repeat",
                        description: Text("右上の＋から家賃やサブスクなど毎月の予定を登録できます。登録後は将来の予定へ自動反映されます。")
                    )
                }
            }
            .navigationTitle("定期予定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentCreate()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("recurring-plan-list-add-button")
                }
            }
            .sheet(isPresented: $viewModel.isShowingEditor) {
                RecurringPlanEditorView(plan: viewModel.editingPlan)
            }
            .confirmationDialog(
                "この定期予定を削除し、未ロックの将来予定も整理します。",
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
            .alert("操作エラー", isPresented: actionErrorBinding) {
                Button("閉じる", role: .cancel) {
                    actionErrorMessage = nil
                }
            } message: {
                Text(actionErrorMessage ?? "")
            }
            .onAppear {
                reloadPlans()
            }
            .onChange(of: reloadToken) { _, _ in
                reloadPlans()
            }
            .onChange(of: navigationState.recurringPlanListCreateRequestID) { _, _ in
                handleCreateRequest()
            }
            .task {
                handleCreateRequest()
            }
        }
    }

    /// 一覧再描画用の更新トークンを返す。
    private var reloadToken: [Date] {
        recurringPlans.map(\.updatedAt)
    }

    /// 削除確認ダイアログ表示有無へ変換する。
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

    /// エラーメッセージの有無をアラート表示有無へ変換する。
    private var actionErrorBinding: Binding<Bool> {
        Binding(
            get: { actionErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    actionErrorMessage = nil
                }
            }
        )
    }

    /// 定期予定一覧を再構築する。
    private func reloadPlans() {
        viewModel.reload(plans: recurringPlans)
    }

    /// 他画面から受けた新規作成要求を処理する。
    private func handleCreateRequest() {
        guard navigationState.recurringPlanListCreateRequestID != nil else {
            return
        }

        viewModel.presentCreate()
        navigationState.consumeRecurringPlanListCreateRequest()
    }

    /// 指定定期予定の有効状態トグルを保存する。
    private func isActiveBinding(for planID: UUID) -> Binding<Bool> {
        Binding(
            get: {
                recurringPlans.first(where: { $0.id == planID })?.isActive ?? false
            },
            set: { newValue in
                updateActiveState(for: planID, isActive: newValue)
            }
        )
    }

    /// 有効状態変更後に将来自動生成予定を再同期する。
    private func updateActiveState(for planID: UUID, isActive: Bool) {
        guard let plan = recurringPlans.first(where: { $0.id == planID }) else {
            return
        }

        let repository = RecurringPlanRepository(modelContext: modelContext)
        let syncCoordinator = RecurringPlanSyncCoordinator()
        let input = RecurringPlanEditorInput(
            flowType: plan.flowType,
            name: plan.name,
            amount: plan.amount,
            dayOfMonth: plan.dayOfMonth,
            startMonth: plan.startMonth,
            endMonth: plan.endMonth,
            isActive: isActive,
            note: plan.note
        )

        do {
            _ = try repository.save(input: input, original: plan, persistChanges: false)
            try syncCoordinator.sync(in: modelContext)
        } catch {
            modelContext.rollback()
            actionErrorMessage = error.localizedDescription
        }
    }

    /// 選択中の定期予定を削除し、将来自動生成予定も再同期する。
    private func deleteSelectedPlan() {
        guard let deletingPlan = viewModel.deletingPlan else {
            return
        }

        let repository = RecurringPlanRepository(modelContext: modelContext)
        let syncCoordinator = RecurringPlanSyncCoordinator()

        do {
            try repository.delete(deletingPlan, persistChanges: false)
            try syncCoordinator.sync(in: modelContext)
            viewModel.deletingPlan = nil
        } catch {
            modelContext.rollback()
            viewModel.deletingPlan = nil
            actionErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    RecurringPlanListView()
}

private struct RecurringPlanRowView: View {
    let row: RecurringPlanRowModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(row.flowType == .income ? Color.green : Color.red)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(row.dayDescription)
                    Text(row.nextOccurrenceDescription)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if row.note.isEmpty == false {
                    Text(row.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            Text(row.displayAmount)
                .font(.headline)
                .foregroundStyle(row.flowType == .income ? .green : .red)
        }
        .padding(.vertical, 4)
        .opacity(row.isActive ? 1 : 0.6)
    }
}
