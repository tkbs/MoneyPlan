import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "ダッシュボードは未実装です",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("残高サマリーとグラフは次の実装で追加します。")
            )
            .navigationTitle("ホーム")
        }
    }
}

#Preview {
    DashboardView()
}
