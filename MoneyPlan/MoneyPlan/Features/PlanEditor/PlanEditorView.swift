import SwiftUI
import SwiftData

struct PlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlanEditorViewModel
    @State private var isShowingDeleteConfirmation = false

    init(plan: TransactionPlan?, recurringPlans: [RecurringPlan]) {
        _viewModel = State(
            initialValue: PlanEditorViewModel(plan: plan, recurringPlans: recurringPlans)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage = viewModel.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                if let saveErrorMessage = viewModel.saveErrorMessage {
                    Section {
                        Text(saveErrorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("定期予定から初期値反映") {
                    Picker("定期予定", selection: recurringPlanSelectionBinding) {
                        Text("選択しない").tag(UUID?.none)
                        ForEach(viewModel.recurringPlans, id: \.id) { plan in
                            Text(plan.name).tag(Optional(plan.id))
                        }
                    }
                }

                Section("基本情報") {
                    Picker("区分", selection: $viewModel.flowType) {
                        ForEach(FlowType.allCases, id: \.self) { flowType in
                            Text(flowType.displayName).tag(flowType)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("日付", selection: $viewModel.date, displayedComponents: .date)

                    TextField("名称", text: $viewModel.name)
                    if let error = viewModel.fieldErrors[.name] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    TextField("金額", text: $viewModel.amountText)
                        .keyboardType(.numberPad)
                    if let error = viewModel.fieldErrors[.amount] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("補足") {
                    TextField("メモ", text: $viewModel.memo, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("表示順", text: $viewModel.sortOrderText)
                        .keyboardType(.numberPad)
                    if let error = viewModel.fieldErrors[.sortOrder] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                }
                if viewModel.isEditing {
                    ToolbarItem(placement: .bottomBar) {
                        Button("削除", role: .destructive) {
                            isShowingDeleteConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "この予定を削除します。",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除する", role: .destructive) {
                    delete()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    /// 定期予定選択を ViewModel へ反映する。
    private var recurringPlanSelectionBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedRecurringPlanID },
            set: { newValue in
                viewModel.selectedRecurringPlanID = newValue
                viewModel.applySelectedRecurringPlan()
            }
        )
    }

    /// 保存実行後にシートを閉じる。
    private func save() {
        do {
            try viewModel.save(using: modelContext)
            dismiss()
        } catch {
        }
    }

    /// 削除実行後にシートを閉じる。
    private func delete() {
        do {
            try viewModel.delete(using: modelContext)
            dismiss()
        } catch {
        }
    }
}

#Preview {
    PlanEditorView(plan: nil, recurringPlans: [])
}
