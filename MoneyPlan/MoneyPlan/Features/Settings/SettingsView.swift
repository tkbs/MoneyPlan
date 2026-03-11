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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("現在の口座残高")
                            .font(.subheadline.weight(.semibold))

                        TextField("例: 120000", text: $viewModel.initialBalanceText)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .initialBalance)

                        Text("残高計算のスタート金額です。アプリを使い始める時点の残高を入れてください。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let error = viewModel.fieldErrors[.initialBalance] {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("残高不足を警告するライン")
                            .font(.subheadline.weight(.semibold))

                        TextField("例: 30000", text: $viewModel.warningBalanceThresholdText)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .warningBalanceThreshold)

                        Text("将来残高がこの金額以下になる日に、ホームや予定一覧で警告を表示します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let error = viewModel.fieldErrors[.warningBalanceThreshold] {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("残高の基準")
                } footer: {
                    Text("どちらも円で入力します。保存するとホーム、予定一覧、月次サマリーの残高表示に反映されます。")
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
