import SwiftUI
import Charts

struct VisualizationView: View {
    @StateObject private var propertyVM = PropertyViewModel()
    @StateObject private var contractVM = ContractViewModel()
    @StateObject private var taskVM = TaskViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio overview
                    PortfolioOverviewCard(propertyVM: propertyVM)

                    // Task breakdown
                    TaskBreakdownCard(taskVM: taskVM)

                    // Contract status
                    ContractStatusCard(contractVM: contractVM)

                    // Monthly revenue estimate
                    RevenueEstimateCard(contractVM: contractVM)
                }
                .padding(16)
            }
            .background(Color.backgroundGray)
            .navigationTitle("分析・可視化")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                async let r1: () = propertyVM.fetchMyProperties()
                async let r2: () = contractVM.fetchContracts()
                async let r3: () = taskVM.fetchTasks()
                _ = await (r1, r2, r3)
            }
        }
    }
}

struct PortfolioOverviewCard: View {
    @ObservedObject var propertyVM: PropertyViewModel

    var totalValue: Double {
        propertyVM.myProperties.compactMap { $0.currentValue }.reduce(0, +)
    }

    var totalArea: Double {
        propertyVM.myProperties.map { $0.area }.reduce(0, +)
    }

    var statusBreakdown: [(String, Int)] {
        let statuses = propertyVM.myProperties.map { $0.status }
        let grouped = Dictionary(grouping: statuses, by: { $0 })
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ポートフォリオ概要")
                .font(.headline).foregroundColor(.textDark)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("物件数").font(.caption).foregroundColor(.textGray)
                    Text("\(propertyVM.myProperties.count)件")
                        .font(.title2).fontWeight(.bold).foregroundColor(.primaryNavy)
                }
                Divider().frame(height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("総面積").font(.caption).foregroundColor(.textGray)
                    Text(String(format: "%.0f㎡", totalArea))
                        .font(.title2).fontWeight(.bold).foregroundColor(.secondaryBlue)
                }
                Divider().frame(height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("総評価額").font(.caption).foregroundColor(.textGray)
                    Text(formatCurrency(totalValue))
                        .font(.title2).fontWeight(.bold).foregroundColor(.successGreen)
                }
            }

            if !statusBreakdown.isEmpty {
                Chart {
                    ForEach(statusBreakdown, id: \.0) { item in
                        BarMark(
                            x: .value("物件数", item.1),
                            y: .value("ステータス", statusLabel(item.0))
                        )
                        .foregroundStyle(statusBarColor(item.0))
                        .cornerRadius(4)
                    }
                }
                .frame(height: CGFloat(statusBreakdown.count * 44))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func statusLabel(_ s: String) -> String {
        switch s {
        case "owned": return "所有中"
        case "rented": return "賃貸中"
        case "for_sale": return "売却中"
        case "vacant": return "空き"
        default: return s
        }
    }

    func statusBarColor(_ s: String) -> Color {
        switch s {
        case "owned": return .primaryNavy
        case "rented": return .successGreen
        case "for_sale": return .warningOrange
        case "vacant": return .accentBlue
        default: return .textGray
        }
    }

    func formatCurrency(_ value: Double) -> String {
        if value >= 100_000_000 { return String(format: "%.1f億", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万", value / 10_000) }
        return "¥\(Int(value))"
    }
}

struct TaskBreakdownCard: View {
    @ObservedObject var taskVM: TaskViewModel

    var taskData: [(String, Int, Color)] {
        [
            ("未着手", taskVM.pendingTasks.count, .accentBlue),
            ("進行中", taskVM.inProgressTasks.count, .warningOrange),
            ("完了", taskVM.completedTasks.count, .successGreen)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("タスク状況")
                .font(.headline).foregroundColor(.textDark)

            HStack(spacing: 20) {
                ForEach(taskData, id: \.0) { item in
                    VStack(spacing: 4) {
                        Text("\(item.1)")
                            .font(.title).fontWeight(.bold).foregroundColor(item.2)
                        Text(item.0).font(.caption).foregroundColor(.textGray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if !taskVM.tasks.isEmpty {
                Chart {
                    ForEach(taskData, id: \.0) { item in
                        SectorMark(
                            angle: .value("件数", max(item.1, 0)),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.2)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 160)
            }

            if taskVM.overdueTasks.count > 0 {
                Label("\(taskVM.overdueTasks.count)件の期限超過タスクがあります", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.errorRed)
                    .padding(10)
                    .background(Color.errorRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ContractStatusCard: View {
    @ObservedObject var contractVM: ContractViewModel

    var contractData: [(String, Int, Color)] {
        [
            ("有効", contractVM.activeContracts.count, .successGreen),
            ("期限切れ間近", contractVM.expiringContracts.count, .warningOrange),
            ("その他", contractVM.contracts.filter { $0.status != "active" }.count, .textGray)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("契約状況")
                .font(.headline).foregroundColor(.textDark)

            HStack(spacing: 0) {
                ForEach(contractData, id: \.0) { item in
                    VStack(spacing: 4) {
                        Text("\(item.1)")
                            .font(.title2).fontWeight(.bold).foregroundColor(item.2)
                        Text(item.0).font(.caption2).foregroundColor(.textGray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if contractVM.expiringContracts.count > 0 {
                Label("\(contractVM.expiringContracts.count)件の契約が30日以内に期限切れになります",
                      systemImage: "calendar.badge.exclamationmark")
                    .font(.caption)
                    .foregroundColor(.warningOrange)
                    .padding(10)
                    .background(Color.warningOrange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RevenueEstimateCard: View {
    @ObservedObject var contractVM: ContractViewModel

    var monthlyRevenue: Double {
        contractVM.activeContracts.compactMap { $0.rentAmount }.reduce(0, +)
    }

    var annualRevenue: Double { monthlyRevenue * 12 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("収益概算")
                .font(.headline).foregroundColor(.textDark)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("月間収益").font(.caption).foregroundColor(.textGray)
                    Text(formatCurrency(monthlyRevenue))
                        .font(.title2).fontWeight(.bold).foregroundColor(.primaryNavy)
                }
                Divider().frame(height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("年間収益（概算）").font(.caption).foregroundColor(.textGray)
                    Text(formatCurrency(annualRevenue))
                        .font(.title2).fontWeight(.bold).foregroundColor(.successGreen)
                }
            }

            Text("※ 有効な賃貸契約の賃料合計を基に計算しています")
                .font(.caption2).foregroundColor(.textGray)
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        if value >= 100_000_000 { return String(format: "%.1f億円", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万円", value / 10_000) }
        return "¥" + (f.string(from: NSNumber(value: value)) ?? "0")
    }
}
