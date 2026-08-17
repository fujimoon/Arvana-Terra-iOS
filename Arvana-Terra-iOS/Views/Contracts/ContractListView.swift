import SwiftUI

struct ContractListView: View {
    @StateObject private var vm = ContractViewModel()
    @State private var showAdd = false
    @State private var selectedStatus: String?

    var filteredContracts: [Contract] {
        guard let status = selectedStatus else { return vm.contracts }
        return vm.contracts.filter { $0.status == status }
    }

    let statuses = [("active","有効"), ("pending","保留"), ("expired","期限切れ"), ("terminated","解除")]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "すべて", isSelected: selectedStatus == nil) { selectedStatus = nil }
                    ForEach(statuses, id: \.0) { s in
                        FilterChip(title: s.1, isSelected: selectedStatus == s.0) { selectedStatus = s.0 }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            .background(Color.surfaceWhite)

            if vm.isLoading && vm.contracts.isEmpty {
                LoadingView()
            } else if filteredContracts.isEmpty {
                EmptyStateView(
                    title: "契約なし",
                    message: "契約を追加してください",
                    systemImage: "doc.text",
                    actionTitle: "契約を追加",
                    action: { showAdd = true }
                )
            } else {
                List {
                    ForEach(filteredContracts) { contract in
                        NavigationLink {
                            ContractDetailView(contract: contract)
                        } label: {
                            ContractRow(contract: contract, vm: vm)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("契約管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchContracts() }
        .sheet(isPresented: $showAdd) {
            AddContractView(vm: vm)
        }
    }
}

struct ContractRow: View {
    let contract: Contract
    @ObservedObject var vm: ContractViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(vm.statusColor(contract.status).opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(vm.statusColor(contract.status))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(contract.tenantName).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                Text(contractTypeLabel(contract.contractType)).font(.caption).foregroundColor(.textGray)
                HStack(spacing: 4) {
                    Text(formatDate(contract.startDate)).font(.caption2).foregroundColor(.textGray)
                    Text("→").font(.caption2).foregroundColor(.textGray)
                    Text(formatDate(contract.endDate)).font(.caption2).foregroundColor(.textGray)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: contract.status, type: .contract)
                if let rent = contract.rentAmount {
                    Text(formatCurrency(rent)).font(.caption).fontWeight(.semibold).foregroundColor(.primaryNavy)
                }
            }
        }
    }

    func contractTypeLabel(_ type: String) -> String {
        switch type {
        case "lease": return "賃貸借契約"
        case "sale": return "売買契約"
        case "land_lease": return "土地賃貸借"
        default: return type
        }
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yy/M/d"
        return f.string(from: date)
    }

    func formatCurrency(_ value: Double) -> String {
        if value >= 10_000 { return String(format: "%.0f万", value / 10_000) }
        return "¥\(Int(value))"
    }
}

struct AddContractView: View {
    @ObservedObject var vm: ContractViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var tenantName = ""
    @State private var tenantContact = ""
    @State private var tenantEmail = ""
    @State private var contractType = "lease"
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(365 * 24 * 3600)
    @State private var rentAmount = ""
    @State private var depositAmount = ""
    @State private var notes = ""

    let contractTypes = [("lease","賃貸借契約"), ("sale","売買契約"), ("land_lease","土地賃貸借")]

    var isValid: Bool { !tenantName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("テナント情報") {
                    TextField("テナント名 *", text: $tenantName)
                    TextField("連絡先", text: $tenantContact).keyboardType(.phonePad)
                    TextField("メールアドレス", text: $tenantEmail).keyboardType(.emailAddress).autocapitalization(.none)
                }
                Section("契約情報") {
                    Picker("契約種別", selection: $contractType) {
                        ForEach(contractTypes, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                }
                Section("金額") {
                    TextField("賃料 (円/月)", text: $rentAmount).keyboardType(.decimalPad)
                    TextField("敷金・保証金 (円)", text: $depositAmount).keyboardType(.decimalPad)
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 80)
                }
            }
            .navigationTitle("契約を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let fmt = ISO8601DateFormatter()
                            let success = await vm.createContract(
                                propertyId: nil, landId: nil, roomId: nil,
                                contractType: contractType, tenantName: tenantName,
                                tenantContact: tenantContact.isEmpty ? nil : tenantContact,
                                tenantEmail: tenantEmail.isEmpty ? nil : tenantEmail,
                                startDate: fmt.string(from: startDate),
                                endDate: fmt.string(from: endDate),
                                rentAmount: Double(rentAmount),
                                depositAmount: Double(depositAmount),
                                notes: notes.isEmpty ? nil : notes
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isValid || vm.isLoading)
                }
            }
        }
    }
}
