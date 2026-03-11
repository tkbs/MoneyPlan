import SwiftUI

struct RecurringPlanListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "定期予定は未実装です",
                systemImage: "repeat",
                description: Text("定期予定一覧と編集は次の実装で追加します。")
            )
            .navigationTitle("定期")
        }
    }
}

#Preview {
    RecurringPlanListView()
}
