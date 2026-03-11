import SwiftUI
import SwiftData

struct RecurringPlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RecurringPlanEditorViewModel
    @State private var isShowingDeleteConfirmation = false

    init(plan: RecurringPlan?) {
        _viewModel = State(initialValue: RecurringPlanEditorViewModel(plan: plan))
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

                Section("基本情報") {
                    Picker("区分", selection: $viewModel.flowType) {
                        ForEach(FlowType.allCases, id: \.self) { flowType in
                            Text(flowType.displayName).tag(flowType)
                        }
                    }
                    .pickerStyle(.segmented)

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

                    Picker("発生日", selection: $viewModel.dayOfMonth) {
                        ForEach(MoneyPlanConstants.minimumRecurringDay...MoneyPlanConstants.maximumRecurringDay, id: \.self) { day in
                            Text("\(day)日").tag(day)
                        }
                    }
                    if let error = viewModel.fieldErrors[.dayOfMonth] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    DatePicker("開始月", selection: $viewModel.startMonth, displayedComponents: .date)

                    Toggle("終了月を設定", isOn: $viewModel.hasEndMonth)
                    if viewModel.hasEndMonth {
                        DatePicker("終了月", selection: $viewModel.endMonth, displayedComponents: .date)
                        if let error = viewModel.fieldErrors[.endMonth] {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("期間")
                } footer: {
                    Text("開始月と終了月は選択した日の月単位で扱います。")
                }

                Section("補足") {
                    Toggle("有効", isOn: $viewModel.isActive)

                    TextField("メモ", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
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
                "この定期予定を削除し、未ロックの将来予定も整理します。",
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

    /// 保存成功時のみシートを閉じる。
    private func save() {
        do {
            try viewModel.save(using: modelContext)
            dismiss()
        } catch {
        }
    }

    /// 削除成功時のみシートを閉じる。
    private func delete() {
        do {
            try viewModel.delete(using: modelContext)
            dismiss()
        } catch {
        }
    }
}

#Preview {
    RecurringPlanEditorView(plan: nil)
}
