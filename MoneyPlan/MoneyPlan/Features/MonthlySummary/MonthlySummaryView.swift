import SwiftUI
import SwiftData

struct MonthlySummaryView: View {
    @Query(
        sort: [
            SortDescriptor(\TransactionPlan.date, order: .forward),
            SortDescriptor(\TransactionPlan.sortOrder, order: .forward),
            SortDescriptor(\TransactionPlan.createdAt, order: .forward),
            SortDescriptor(\TransactionPlan.id, order: .forward),
        ]
    ) private var plans: [TransactionPlan]
    @Query(sort: [SortDescriptor(\AppSetting.createdAt, order: .forward)]) private var settings: [AppSetting]
    @State private var viewModel: MonthlySummaryViewModel

    init(initialMonth: Date = .now) {
        _viewModel = State(
            initialValue: MonthlySummaryViewModel(targetMonth: initialMonth)
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthlySummaryHighlightsView(summary: viewModel.summary)
                }

                Section("日別集計") {
                    ForEach(viewModel.summary.dailySummaries) { row in
                        MonthlySummaryRowView(row: row)
                    }

                    if viewModel.summary.dailySummaries.isEmpty {
                        ContentUnavailableView(
                            "対象月の予定がありません",
                            systemImage: "calendar",
                            description: Text("月を切り替えると別の集計を確認できます。")
                        )
                    }
                }
            }
            .navigationTitle("月次サマリー")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    MonthlySummaryMonthSwitcherView(
                        targetMonth: viewModel.targetMonth,
                        onPrevious: viewModel.showPreviousMonth,
                        onNext: viewModel.showNextMonth
                    )
                }
            }
            .onAppear {
                reloadSummary()
            }
            .onChange(of: planReloadToken) { _, _ in
                reloadSummary()
            }
            .onChange(of: settings.first?.initialBalance) { _, _ in
                reloadSummary()
            }
            .onChange(of: settings.first?.warningBalanceThreshold) { _, _ in
                reloadSummary()
            }
            .onChange(of: viewModel.targetMonth) { _, _ in
                reloadSummary()
            }
        }
    }

    /// 予定更新の再読込判定に使うトークン。
    private var planReloadToken: [Date] {
        plans.map(\.updatedAt)
    }

    /// 現在の対象月でサマリーを再構築する。
    private func reloadSummary() {
        viewModel.reload(
            plans: plans,
            initialBalance: settings.first?.initialBalance ?? 0,
            warningThreshold: settings.first?.warningBalanceThreshold ?? 0
        )
    }
}

private struct MonthlySummaryHighlightsView: View {
    let summary: MonthlySummary

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MonthlySummaryMetricCard(
                    title: "入金",
                    amount: summary.incomeTotal,
                    tint: .green
                )
                MonthlySummaryMetricCard(
                    title: "出金",
                    amount: summary.expenseTotal,
                    tint: .red
                )
            }

            HStack(spacing: 12) {
                MonthlySummaryMetricCard(
                    title: "月末残高",
                    amount: summary.endingBalance,
                    tint: .blue
                )
                MonthlySummaryMetricCard(
                    title: "最低残高",
                    amount: summary.lowestBalance,
                    tint: summary.lowestBalance < 0 ? .red : .orange
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

private struct MonthlySummaryMetricCard: View {
    let title: String
    let amount: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.string(from: amount))
                .font(.headline)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct MonthlySummaryRowView: View {
    let row: DailySummaryRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.date, format: .dateTime.month().day().weekday(.abbreviated))
                    .font(.headline)

                Spacer()

                Text("\(row.planCount)件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Text("入金 \(CurrencyFormatter.string(from: row.incomeTotal))")
                    .foregroundStyle(.green)
                Text("出金 \(CurrencyFormatter.string(from: row.expenseTotal))")
                    .foregroundStyle(.red)
            }
            .font(.caption)

            Text("日末残高 \(CurrencyFormatter.string(from: row.endingBalance))")
                .font(.caption)
                .foregroundStyle(row.warningState.tintColor)
        }
        .padding(.vertical, 4)
    }
}

private struct MonthlySummaryMonthSwitcherView: View {
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
    MonthlySummaryView()
}
