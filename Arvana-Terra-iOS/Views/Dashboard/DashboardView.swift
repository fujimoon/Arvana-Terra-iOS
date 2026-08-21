import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var propertyVM = PropertyViewModel()
    @StateObject private var landVM = LandViewModel()
    @StateObject private var taskVM = TaskViewModel()
    @StateObject private var contractVM = ContractViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader

                    // Summary stats
                    summaryCards

                    // Occupancy chart
                    occupancySection

                    // Pending tasks
                    pendingTasksSection

                    // Expiring contracts
                    expiringContractsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.backgroundGray)
            .navigationTitle("ダッシュボード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.primaryNavy)
                    }
                }
            }
            .task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await propertyVM.fetchMyProperties() }
                    group.addTask { await landVM.fetchMyLands() }
                    group.addTask { await taskVM.fetchTasks() }
                    group.addTask { await contractVM.fetchContracts() }
                }
            }
        }
    }

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("おかえりなさい")
                    .font(.subheadline)
                    .foregroundColor(.textGray)
                Text(authVM.currentUser?.name ?? "ユーザー")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textDark)
            }
            Spacer()
            Circle()
                .fill(Color.accentBlue.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(authVM.currentUser?.name.prefix(1) ?? "U"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryNavy)
                )
        }
        .padding(.top, 8)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardCard(
                title: "物件数",
                value: "\(propertyVM.myProperties.count)",
                unit: "件",
                icon: "building.2.fill",
                color: .primaryNavy
            )
            DashboardCard(
                title: "土地数",
                value: "\(landVM.myLands.count)",
                unit: "件",
                icon: "map.fill",
                color: .secondaryBlue
            )
            DashboardCard(
                title: "契約数",
                value: "\(contractVM.activeContracts.count)",
                unit: "件",
                icon: "doc.text.fill",
                color: .successGreen
            )
            DashboardCard(
                title: "未完了タスク",
                value: "\(taskVM.pendingTasks.count + taskVM.inProgressTasks.count)",
                unit: "件",
                icon: "checkmark.circle.fill",
                color: taskVM.overdueTasks.isEmpty ? .accentBlue : .errorRed
            )
        }
    }

    private var occupancySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("稼働状況")
                .font(.headline)
                .foregroundColor(.textDark)

            if propertyVM.myProperties.isEmpty {
                Text("物件を登録すると稼働状況が表示されます")
                    .font(.caption)
                    .foregroundColor(.textGray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(propertyVM.myProperties.prefix(3)) { property in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(property.name)
                                    .font(.subheadline)
                                    .foregroundColor(.textDark)
                                Text(property.address)
                                    .font(.caption)
                                    .foregroundColor(.textGray)
                                    .lineLimit(1)
                            }
                            Spacer()
                            StatusBadge(status: property.status, type: .property)
                        }
                        .padding(12)
                        .background(Color.surfaceWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var pendingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("未完了タスク")
                    .font(.headline)
                    .foregroundColor(.textDark)
                Spacer()
                NavigationLink("すべて表示") {
                    TaskManageView()
                }
                .font(.caption)
                .foregroundColor(.accentBlue)
            }

            if taskVM.pendingTasks.isEmpty && taskVM.inProgressTasks.isEmpty {
                EmptyStateView(
                    title: "タスクなし",
                    message: "未完了のタスクはありません",
                    systemImage: "checkmark.circle"
                )
                .frame(height: 100)
            } else {
                VStack(spacing: 8) {
                    ForEach((taskVM.pendingTasks + taskVM.inProgressTasks).prefix(3)) { task in
                        TaskRowView(task: task)
                    }
                }
            }
        }
    }

    private var expiringContractsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("期限が近い契約")
                    .font(.headline)
                    .foregroundColor(.textDark)
                Spacer()
                NavigationLink("すべて表示") {
                    ContractListView()
                }
                .font(.caption)
                .foregroundColor(.accentBlue)
            }

            if contractVM.expiringContracts.isEmpty {
                Text("期限が近い契約はありません")
                    .font(.caption)
                    .foregroundColor(.textGray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(contractVM.expiringContracts.prefix(3)) { contract in
                        ContractRowView(contract: contract)
                    }
                }
            }
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.subheadline)
                            .foregroundColor(color)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.textDark)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.textGray)
                }
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textGray)
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TaskRowView: View {
    let task: AppTask

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priorityColor(task.priority).opacity(0.15))
                .frame(width: 8, height: 8)
                .overlay(Circle().fill(priorityColor(task.priority)).frame(width: 8, height: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.textDark)
                    .lineLimit(1)
                if let dueDate = task.dueDate {
                    Text("期限: \(formatDate(dueDate))")
                        .font(.caption)
                        .foregroundColor(.textGray)
                }
            }
            Spacer()
            StatusBadge(status: task.status, type: .task)
        }
        .padding(12)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "high": return .errorRed
        case "medium": return .warningOrange
        default: return .successGreen
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M/d"
        displayFormatter.locale = Locale(identifier: "ja_JP")
        return displayFormatter.string(from: date)
    }
}

struct ContractRowView: View {
    let contract: Contract

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundColor(.primaryNavy)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(contract.tenantName)
                    .font(.subheadline)
                    .foregroundColor(.textDark)
                    .lineLimit(1)
                Text("期限: \(formatDate(contract.endDate))")
                    .font(.caption)
                    .foregroundColor(.warningOrange)
            }
            Spacer()
            StatusBadge(status: contract.status, type: .contract)
        }
        .padding(12)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy/M/d"
        displayFormatter.locale = Locale(identifier: "ja_JP")
        return displayFormatter.string(from: date)
    }
}
