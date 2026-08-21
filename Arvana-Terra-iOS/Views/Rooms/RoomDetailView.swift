import SwiftUI

struct RoomDetailView: View {
    let roomId: String
    @State private var room: Room?
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var showingAddTenant = false
    @State private var showingEditRoom = false

    var activeTenant: Tenant? { room?.tenants?.first { $0.status == "active" } }
    var payments: [Payment] { room?.payments ?? [] }
    var overduePayments: [Payment] { payments.filter { $0.status == "overdue" } }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let room = room {
                ScrollView {
                    VStack(spacing: 0) {
                        // Overdue Warning
                        if !overduePayments.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("\(overduePayments.count)件の滞納が発生しています")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.top)
                        }

                        // Tab Picker
                        Picker("", selection: $selectedTab) {
                            Text("部屋情報").tag(0)
                            Text("入居者").tag(1)
                            Text("入金管理").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        // Tab Content
                        switch selectedTab {
                        case 0: RoomInfoTab(room: room)
                        case 1: TenantTab(activeTenant: activeTenant, roomId: roomId) { Task { await loadRoom() } }
                        default: PaymentsTab(payments: payments) { Task { await loadRoom() } }
                        }
                    }
                }
                .navigationTitle(room.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("編集") { showingEditRoom = true }
                    }
                }
                .sheet(isPresented: $showingEditRoom) {
                    RoomFormView(propertyId: room.propertyId, existingRoom: room) { _ in Task { await loadRoom() } }
                }
            }
        }
        .task { await loadRoom() }
    }

    private func loadRoom() async {
        isLoading = true
        defer { isLoading = false }
        room = try? await RoomService.shared.getRoomById(id: roomId)
    }
}

struct RoomInfoTab: View {
    let room: Room

    var body: some View {
        VStack(spacing: 12) {
            InfoCard(title: "基本情報") {
                InfoRow("部屋番号", room.name)
                InfoRow("階数", room.floor.map { "\($0)階" } ?? "-")
                InfoRow("間取り", room.roomType ?? "-")
                InfoRow("面積", room.area.map { "\(Int($0))m2" } ?? "-")
                InfoRow("月額賃料", room.rentAmount.map { "¥\(Int($0).formatted())" } ?? "-")
            }

            if let spots = room.parkingSpots, !spots.isEmpty {
                InfoCard(title: "駐車場") {
                    ForEach(spots) { spot in
                        HStack {
                            Text(spot.spotNumber).fontWeight(.medium)
                            Spacer()
                            Text(spot.isOccupied ? "使用中" : "空き")
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(spot.isOccupied ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                                .foregroundColor(spot.isOccupied ? .blue : .green)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            if let notes = room.notes, !notes.isEmpty {
                InfoCard(title: "メモ・所見") {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

struct TenantTab: View {
    let activeTenant: Tenant?
    let roomId: String
    let onRefresh: () -> Void
    @State private var showingAddTenant = false
    @State private var showingAddFamily = false

    var body: some View {
        VStack(spacing: 12) {
            if let tenant = activeTenant {
                // Basic Info
                InfoCard(title: "基本情報") {
                    InfoRow("氏名", tenant.name)
                    InfoRow("フリガナ", tenant.nameKana ?? "-")
                    InfoRow("生年月日", tenant.birthDate.flatMap { formatDate($0) } ?? "-")
                    InfoRow("性別", tenant.gender == "male" ? "男性" : tenant.gender == "female" ? "女性" : tenant.gender ?? "-")
                    InfoRow("電話", tenant.phone ?? "-")
                    InfoRow("メール", tenant.email ?? "-")
                    InfoRow("職業", tenant.occupation ?? "-")
                    InfoRow("勤務先", tenant.workplace ?? "-")
                    InfoRow("年収", tenant.annualIncome.map { "¥\(Int($0).formatted())" } ?? "-")
                }

                // Emergency Contact
                InfoCard(title: "緊急連絡先") {
                    InfoRow("氏名", tenant.emergencyContactName ?? "-")
                    InfoRow("続柄", tenant.emergencyContactRelationship ?? "-")
                    InfoRow("電話", tenant.emergencyContactPhone ?? "-")
                }

                // Parking
                InfoCard(title: "駐車場") {
                    InfoRow("利用", tenant.parkingUsed ? "利用中" : "利用なし")
                    if tenant.parkingUsed {
                        InfoRow("駐車場番号", tenant.parkingSpotNumber ?? "-")
                        InfoRow("ナンバープレート", tenant.licensePlateNumber ?? "-")
                    }
                }

                // Family Members
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("家族構成")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#1B3A6B"))
                        Spacer()
                        Button {
                            showingAddFamily = true
                        } label: {
                            Label("追加", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }

                    if let members = tenant.familyMembers, !members.isEmpty {
                        ForEach(members) { member in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color(hex: "#4A90D9"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name).fontWeight(.medium)
                                    if let kana = member.nameKana {
                                        Text(kana).font(.caption).foregroundColor(.secondary)
                                    }
                                    Text("\(member.relationship)\(member.birthDate.flatMap { " / \(formatDate($0))" } ?? "")\(member.occupation.map { " / \($0)" } ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    } else {
                        Text("家族情報なし")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }
                }
                .padding(14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // Contract
                InfoCard(title: "契約情報") {
                    InfoRow("入居日", tenant.moveInDate.flatMap { formatDate($0) } ?? "-")
                    InfoRow("契約終了日", tenant.contractEndDate.flatMap { formatDate($0) } ?? "-")
                    InfoRow("月額賃料", tenant.rentAmount.map { "¥\(Int($0).formatted())" } ?? "-")
                    InfoRow("敷金", tenant.depositAmount.map { "¥\(Int($0).formatted())" } ?? "-")
                    InfoRow("礼金", tenant.keyMoneyAmount.map { "¥\(Int($0).formatted())" } ?? "-")
                }

                if let notes = tenant.notes, !notes.isEmpty {
                    InfoCard(title: "メモ") {
                        Text(notes).font(.subheadline).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("入居者が登録されていません")
                        .foregroundColor(.gray)
                    Button {
                        showingAddTenant = true
                    } label: {
                        Label("入居者を登録", systemImage: "plus")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#1B3A6B"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .sheet(isPresented: $showingAddTenant) {
            TenantFormView(roomId: roomId, onSaved: onRefresh)
        }
        .sheet(isPresented: $showingAddFamily) {
            if let tenant = activeTenant {
                FamilyMemberFormView(tenantId: tenant.id, onSaved: onRefresh)
            }
        }
    }

    private func formatDate(_ isoString: String) -> String? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return nil }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.locale = Locale(identifier: "ja_JP")
        return out.string(from: date)
    }
}

struct PaymentsTab: View {
    let payments: [Payment]
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if payments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "yensign.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("入金記録がありません")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(payments) { payment in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(payment.dueDate) ?? payment.dueDate)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("¥\(Int(payment.amount).formatted())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            PaymentStatusBadge(status: payment.status, label: payment.statusLabel)
                            if payment.status != "paid" {
                                Button("支払済にする") {
                                    Task {
                                        try? await TenantService.shared.updatePaymentStatus(id: payment.id, status: "paid")
                                        onRefresh()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(12)
                    .background(payment.status == "overdue" ? Color.red.opacity(0.05) : Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private func formatDate(_ isoString: String) -> String? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return nil }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.locale = Locale(identifier: "ja_JP")
        return out.string(from: date)
    }
}

struct PaymentStatusBadge: View {
    let status: String
    let label: String

    var color: Color {
        switch status {
        case "paid": return .green
        case "pending": return .orange
        case "overdue": return .red
        default: return .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "#1B3A6B"))
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) {
        self.label = label; self.value = value
    }
    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).foregroundColor(.secondary).frame(width: 100, alignment: .leading)
            Text(value).font(.subheadline).foregroundColor(.primary).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
