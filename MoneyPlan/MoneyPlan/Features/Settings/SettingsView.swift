import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [
            SortDescriptor(\AppSetting.createdAt, order: .forward),
            SortDescriptor(\AppSetting.id, order: .forward),
        ]
    ) private var settings: [AppSetting]
    @State private var viewModel = SettingsViewModel()
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case initialBalance
        case warningBalanceThreshold
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

                Section {
                    TextField("初期残高", text: $viewModel.initialBalanceText)
                        .keyboardType(.numbersAndPunctuation)
                        .focused($focusedField, equals: .initialBalance)
                    if let error = viewModel.fieldErrors[.initialBalance] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    TextField("警告閾値", text: $viewModel.warningBalanceThresholdText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .warningBalanceThreshold)
                    if let error = viewModel.fieldErrors[.warningBalanceThreshold] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("残高計算")
                } footer: {
                    Text("警告閾値以下の残高日は予定一覧や今後のダッシュボードで警告表示します。")
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        dismissKeyboard()
                    }
                }
            }
            .task {
                ensureSettingLoaded()
            }
            .onChange(of: settings.first?.updatedAt) { _, _ in
                ensureSettingLoaded()
            }
        }
    }

    /// 設定レコードを確保し、フォームへ反映する。
    private func ensureSettingLoaded() {
        if let setting = settings.first {
            viewModel.load(setting: setting)
            return
        }

        do {
            let repository = SettingRepository(modelContext: modelContext)
            let setting = try repository.fetchOrCreate()
            viewModel.load(setting: setting)
        } catch {
            viewModel.saveErrorMessage = error.localizedDescription
        }
    }

    /// 入力内容を保存する。
    private func save() {
        dismissKeyboard()
        do {
            try viewModel.save(using: modelContext)
        } catch {
        }
    }

    /// フォーカスを外してキーボードを閉じる。
    private func dismissKeyboard() {
        focusedField = nil
    }
}

#Preview {
    SettingsView()
}
