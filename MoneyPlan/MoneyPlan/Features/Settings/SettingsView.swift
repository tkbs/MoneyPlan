import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "設定画面は未実装です",
                systemImage: "gearshape",
                description: Text("初期残高と警告閾値の編集は次の実装で追加します。")
            )
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView()
}
