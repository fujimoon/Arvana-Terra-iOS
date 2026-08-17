import SwiftUI

struct OpportunitiesView: View {
    @StateObject private var vm = OpportunityViewModel()
    @State private var selectedType: String?

    let types = [("purchase","購入"), ("sale","売却"), ("lease","賃貸"), ("development","開発"), ("partnership","共同")]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "すべて", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        ForEach(types, id: \.0) { type in
                            FilterChip(title: type.1, isSelected: selectedType == type.0) {
                                selectedType = type.0
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .background(Color.surfaceWhite)

                if vm.isLoading && vm.opportunities.isEmpty {
                    LoadingView()
                } else if vm.filteredOpportunities.isEmpty {
                    EmptyStateView(
                        title: "案件なし",
                        message: "ビジネス案件がありません",
                        systemImage: "briefcase"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vm.filteredOpportunities) { opp in
                                OpportunityCard(opportunity: opp, vm: vm)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color.backgroundGray)
                }
            }
            .navigationTitle("ビジネス機会")
            .task {
                vm.filterType = selectedType
                await vm.fetchOpportunities()
            }
            .onChange(of: selectedType) { newValue in
                vm.filterType = newValue
            }
        }
    }
}

struct OpportunityCard: View {
    let opportunity: BusinessOpportunity
    @ObservedObject var vm: OpportunityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(opportunity.title)
                        .font(.headline).fontWeight(.bold).foregroundColor(.textDark).lineLimit(2)
                    if let type = vm.typeLabel(opportunity.opportunityType) as String? {
                        Text(type).font(.caption).foregroundColor(.textGray)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(vm.riskLabel(opportunity.riskLevel))
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(vm.riskColor(opportunity.riskLevel))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(vm.riskColor(opportunity.riskLevel).opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(opportunity.description)
                .font(.subheadline).foregroundColor(.textGray).lineLimit(3)

            if let location = opportunity.location {
                Label(location, systemImage: "mappin.circle.fill")
                    .font(.caption).foregroundColor(.textGray)
            }

            Divider()

            HStack(spacing: 16) {
                if let budget = opportunity.budget {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("予算").font(.caption2).foregroundColor(.textGray)
                        Text(vm.formatCurrency(budget)).font(.caption).fontWeight(.semibold).foregroundColor(.primaryNavy)
                    }
                }
                if let expectedReturn = opportunity.expectedReturn {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("期待収益率").font(.caption2).foregroundColor(.textGray)
                        Text(String(format: "%.1f%%", expectedReturn)).font(.caption).fontWeight(.semibold).foregroundColor(.successGreen)
                    }
                }
                Spacer()
                if let deadline = opportunity.deadline {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("期限").font(.caption2).foregroundColor(.textGray)
                        Text(formatDate(deadline)).font(.caption).foregroundColor(.warningOrange)
                    }
                }
            }

            if !opportunity.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(opportunity.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2).foregroundColor(.accentBlue)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Color.accentBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy/M/d"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}
