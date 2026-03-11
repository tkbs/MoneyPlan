import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(
        sort: [
            SortDescriptor(\TransactionPlan.date, order: .forward),
            SortDescriptor(\TransactionPlan.sortOrder, order: .forward),
            SortDescriptor(\TransactionPlan.createdAt, order: .forward),
            SortDescriptor(\TransactionPlan.id, order: .forward),
        ]
    ) private var plans: [TransactionPlan]
    @Query(sort: [SortDescriptor(\AppSetting.createdAt, order: .forward)]) private var settings: [AppSetting]
    @Query(
        sort: [
            SortDescriptor(\RecurringPlan.dayOfMonth, order: .forward),
            SortDescriptor(\RecurringPlan.createdAt, order: .forward),
        ]
    ) private var recurringPlans: [RecurringPlan]
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DashboardBalanceCardView(summary: viewModel.summary)
                    DashboardWarningCardView(summary: viewModel.summary)
                    DashboardGraphSectionView(
                        summary: viewModel.summary,
                        graphRange: $viewModel.graphRange
                    )
                    DashboardUpcomingPlansSectionView(
                        rows: viewModel.summary.upcomingPlans,
                        onTap: presentEditor(for:)
                    )

                    Button {
                        viewModel.presentMonthlySummary(for: .now)
                    } label: {
                        HStack {
                            Label("月次サマリーを見る", systemImage: "calendar.badge.clock")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .font(.headline)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .sheet(isPresented: $viewModel.isShowingEditor) {
                PlanEditorView(
                    plan: viewModel.editingPlan,
                    recurringPlans: recurringPlans
                )
            }
            .sheet(isPresented: $viewModel.isShowingMonthlySummary) {
                MonthlySummaryView(initialMonth: viewModel.selectedMonth)
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
            .onChange(of: viewModel.graphRange) { _, _ in
                reloadSummary()
            }
        }
    }

    /// 予定更新の再読込判定に使うトークン。
    private var planReloadToken: [Date] {
        plans.map(\.updatedAt)
    }

    /// 現在データからダッシュボードサマリーを再構築する。
    private func reloadSummary() {
        viewModel.reload(
            plans: plans,
            initialBalance: settings.first?.initialBalance ?? 0,
            warningThreshold: settings.first?.warningBalanceThreshold ?? 0
        )
    }

    /// タップされた予定の編集シートを開く。
    private func presentEditor(for row: UpcomingPlanRowModel) {
        guard let plan = plans.first(where: { $0.id == row.planID }) else {
            return
        }
        viewModel.presentEdit(for: plan)
    }
}

private struct DashboardBalanceCardView: View {
    let summary: DashboardSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("現在残高")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.string(from: summary.currentBalance))
                .font(.system(size: 34, weight: .bold, design: .rounded))

            HStack(spacing: 12) {
                DashboardMetricChipView(
                    title: "今月入金",
                    amount: summary.monthlyIncomeTotal,
                    tint: .green
                )
                DashboardMetricChipView(
                    title: "今月出金",
                    amount: summary.monthlyExpenseTotal,
                    tint: .red
                )
                DashboardMetricChipView(
                    title: "最低残高",
                    amount: summary.lowestProjectedBalance,
                    tint: summary.lowestProjectedBalance < 0 ? .red : .orange
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.16), Color.cyan.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
}

private struct DashboardMetricChipView: View {
    let title: String
    let amount: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(CurrencyFormatter.string(from: amount))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct DashboardWarningCardView: View {
    let summary: DashboardSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(warningTitle)
                .font(.headline)
            Text(summary.warningMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 20))
    }

    private var warningTitle: String {
        switch summary.warningState {
        case .none:
            "残高警告はありません"
        case .warning:
            "警告閾値に近づいています"
        case .negative:
            "残高不足の見込みがあります"
        }
    }

    private var backgroundColor: Color {
        switch summary.warningState {
        case .none:
            Color.green.opacity(0.1)
        case .warning:
            Color.orange.opacity(0.12)
        case .negative:
            Color.red.opacity(0.12)
        }
    }
}

private struct DashboardGraphSectionView: View {
    let summary: DashboardSummary
    @Binding var graphRange: DashboardGraphRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("残高推移")
                    .font(.headline)
                Spacer()
                Picker("表示範囲", selection: $graphRange) {
                    ForEach(DashboardGraphRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            Chart {
                ForEach(summary.graphPoints) { point in
                    AreaMark(
                        x: .value("日付", point.date),
                        yStart: .value("基準", 0),
                        yEnd: .value("残高", point.balance)
                    )
                    .foregroundStyle(Color.blue.opacity(0.12))

                    LineMark(
                        x: .value("日付", point.date),
                        y: .value("残高", point.balance)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日付", point.date),
                        y: .value("残高", point.balance)
                    )
                    .foregroundStyle(point.balance < 0 ? .red : .blue)
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct DashboardUpcomingPlansSectionView: View {
    let rows: [UpcomingPlanRowModel]
    let onTap: (UpcomingPlanRowModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("直近予定")
                .font(.headline)

            if rows.isEmpty {
                ContentUnavailableView(
                    "今後の予定はありません",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("予定を追加するとここに表示されます。")
                )
            } else {
                ForEach(rows) { row in
                    Button {
                        onTap(row)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(row.flowType == .income ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(row.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if row.isAutoGenerated {
                                        Text("自動")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(row.date, format: .dateTime.month().day().weekday(.abbreviated))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if row.memo.isEmpty == false {
                                    Text(row.memo)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Text(row.displayAmount)
                                .font(.headline)
                                .foregroundStyle(row.warningState.tintColor)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
