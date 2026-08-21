import SwiftUI

struct ContractDetailView: View {
    let contract: Contract
    @StateObject private var vm = ContractViewModel()
    @State private var showStatusUpdate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contract.tenantName)
                            .font(.title2).fontWeight(.bold).foregroundColor(.textDark)
                        Text(contractTypeLabel(contract.contractType))
                            .font(.subheadline).foregroundColor(.textGray)
                    }
                    Spacer()
                    StatusBadge(status: contract.status, type: .contract)
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Contract details
                VStack(spacing: 12) {
                    if let contact = contract.tenantContact {
                        DetailRow(label: "連絡先", value: contact, icon: "phone.fill")
                    }
                    if let email = contract.tenantEmail {
                        DetailRow(label: "メール", value: email, icon: "envelope.fill")
                    }
                    DetailRow(label: "開始日", value: formatDate(contract.startDate), icon: "calendar")
                    DetailRow(label: "終了日", value: formatDate(contract.endDate), icon: "calendar.badge.exclamationmark")
                    if let rent = contract.rentAmount {
                        DetailRow(label: "賃料", value: formatCurrency(rent) + "/月", icon: "yensign.circle")
                    }
                    if let deposit = contract.depositAmount {
                        DetailRow(label: "敷金・保証金", value: formatCurrency(deposit), icon: "banknote.fill")
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let notes = contract.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備考").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        Text(notes).font(.body).foregroundColor(.textDark)
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Status actions
                if contract.status == "active" {
                    VStack(spacing: 12) {
                        Button(action: {
                            Task { await vm.updateContractStatus(contract.id, status: "terminated") }
                        }) {
                            Label("契約を解除", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.errorRed)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("契約詳細")
        .navigationBarTitleDisplayMode(.inline)
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
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }

    func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return "¥" + (f.string(from: NSNumber(value: value)) ?? "0")
    }
}
