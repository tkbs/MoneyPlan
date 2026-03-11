import SwiftUI

struct PlanListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "予定一覧は未実装です",
                systemImage: "calendar",
                description: Text("一覧表示と編集導線は次の実装で追加します。")
            )
            .navigationTitle("予定")
        }
    }
}

#Preview {
    PlanListView()
}
