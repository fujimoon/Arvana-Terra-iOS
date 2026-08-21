import SwiftUI

struct PaymentListView: View {
    let propertyId: String
    @StateObject private var vm = PaymentViewModel()
    @State private var showAdd = false
    @State private var statusFilter: String? = nil

    let statuses = [("paid","支払済"), ("pending","未払"), ("late","遅延"), ("overdue","滞納")]

    var filteredPayments: [Payment] {
        guard let s = statusFilter else { return vm.payments }
        return vm.payments.filter { $0.status == s }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary
            HStack(spacing: 12) {
                SummaryBox(title: "合計", value: formatCurrency(vm.totalAmount), color: .primaryNavy)
                SummaryBox(title: "支払済", value: "\(vm.paidCount)件", color: .successGreen)
                SummaryBox(title: "遅延・滞納", value: "\(vm.lateCount)件", color: .errorRed)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.surfaceWhite)

            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "すべて", isSelected: statusFilter == nil) { statusFilter = nil }
                    ForEach(statuses, id: \.0) { s in
                        FilterChip(title: s.1, isSelected: statusFilter == s.0) { statusFilter = s.0 }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
            .background(Color.surfaceWhite)

            if vm.isLoading && vm.payments.isEmpty {
                LoadingView()
            } else if filteredPayments.isEmpty {
                EmptyStateView(
                    title: "入金なし",
                    message: "入金レコードを追加してください",
                    systemImage: "yensign.circle",
                    actionTitle: "入金を追加",
                    action: { showAdd = true }
                )
            } else {
                List {
                    ForEach(filteredPayments) { payment in
                        PaymentRow(payment: payment, vm: vm)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("入金管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchPayments(propertyId: propertyId) }
        .sheet(isPresented: $showAdd) {
            AddPaymentView(vm: vm, propertyId: propertyId)
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "¥0"
    }
}

struct SummaryBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundColor(.textGray)
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.backgroundGray)
        .cornerRadius(8)
    }
}

struct PaymentRow: View {
    let payment: Payment
    @ObservedObject var vm: PaymentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(payment.room?.roomNumber ?? String(payment.roomId.prefix(8)))
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                    if let tenantName = payment.tenant?.name {
                        Text(tenantName).font(.caption).foregroundColor(.textGray)
                    }
                }
                Spacer()
                Text(formatCurrency(payment.amount))
                    .font(.subheadline).fontWeight(.bold).foregroundColor(.textDark)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("期日: \(formatDate(payment.dueDate))")
                        .font(.caption2).foregroundColor(.textGray)
                    if let paid = payment.paidDate {
                        Text("支払日: \(formatDate(paid))")
                            .font(.caption2).foregroundColor(.textGray)
                    }
                }
                Spacer()
                Text(vm.statusLabel(payment.status))
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(vm.statusColor(payment.status))
            }
        }
        .padding(.vertical, 4)
    }

    func formatDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let date = f.date(from: iso) else { return String(iso.prefix(10)) }
        let df = DateFormatter()
        df.dateFormat = "yy/M/d"
        return df.string(from: date)
    }

    func formatCurrency(_ value: Double) -> String {
        if value >= 10_000 { return String(format: "%.0f万円", value / 10_000) }
        return "¥\(Int(value))"
    }
}

struct AddPaymentView: View {
    @ObservedObject var vm: PaymentViewModel
    let propertyId: String
    @Environment(\.dismiss) private var dismiss

    @State private var roomId = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var paidDate: Date? = nil
    @State private var status = "pending"
    @State private var notes = ""
    @State private var hasPaidDate = false

    let statuses = [("pending","未払"), ("paid","支払済"), ("late","遅延"), ("overdue","滞納")]

    var isValid: Bool { !roomId.isEmpty && !amount.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("部屋ID *", text: $roomId)
                        .autocapitalization(.none)
                    TextField("金額 (円) *", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Section("日程") {
                    DatePicker("支払期日", selection: $dueDate, displayedComponents: .date)
                    Toggle("支払日を設定", isOn: $hasPaidDate)
                    if hasPaidDate {
                        DatePicker("支払日", selection: Binding(
                            get: { paidDate ?? Date() },
                            set: { paidDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                Section("ステータス") {
                    Picker("ステータス", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 60)
                }
            }
            .navigationTitle("入金を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let fmt = ISO8601DateFormatter()
                            let request = CreatePaymentRequest(
                                roomId: roomId,
                                tenantId: nil,
                                amount: Double(amount) ?? 0,
                                dueDate: fmt.string(from: dueDate),
                                paidDate: hasPaidDate ? fmt.string(from: paidDate ?? Date()) : nil,
                                status: status,
                                notes: notes.isEmpty ? nil : notes
                            )
                            let success = await vm.createPayment(propertyId: propertyId, request: request)
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isValid || vm.isLoading)
                }
            }
        }
    }
}
