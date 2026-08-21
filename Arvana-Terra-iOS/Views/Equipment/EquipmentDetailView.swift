import SwiftUI

struct EquipmentDetailView: View {
    let equipment: Equipment
    @StateObject private var vm = EquipmentViewModel()
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(equipment.name)
                            .font(.title2).fontWeight(.bold).foregroundColor(.textDark)
                        Text(categoryLabel(equipment.category))
                            .font(.subheadline).foregroundColor(.textGray)
                    }
                    Spacer()
                    StatusBadge(status: equipment.status, type: .equipment)
                }

                Divider()

                // Details
                VStack(spacing: 12) {
                    if let mfr = equipment.manufacturer {
                        DetailRow(label: "メーカー", value: mfr, icon: "building.2")
                    }
                    if let model = equipment.model {
                        DetailRow(label: "型番", value: model, icon: "barcode")
                    }
                    if let serial = equipment.serialNumber {
                        DetailRow(label: "シリアル番号", value: serial, icon: "number")
                    }
                    if let install = equipment.installationDate {
                        DetailRow(label: "設置日", value: formatDate(install), icon: "calendar.badge.plus")
                    }
                    if let warranty = equipment.warrantyExpiry {
                        DetailRow(label: "保証期限", value: formatDate(warranty), icon: "shield.fill")
                    }
                    if let lastMaint = equipment.lastMaintenanceDate {
                        DetailRow(label: "最終メンテナンス", value: formatDate(lastMaint), icon: "wrench.fill")
                    }
                    if let nextMaint = equipment.nextMaintenanceDate {
                        DetailRow(label: "次回メンテナンス", value: formatDate(nextMaint), icon: "calendar.badge.clock")
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let notes = equipment.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備考").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        Text(notes).font(.body).foregroundColor(.textDark)
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Maintenance button
                Button(action: { showEdit = true }) {
                    Label("メンテナンス記録を更新", systemImage: "wrench.and.screwdriver.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryNavy)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("設備詳細")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            UpdateEquipmentStatusView(vm: vm, equipment: equipment)
        }
    }

    func categoryLabel(_ cat: String) -> String {
        switch cat {
        case "electrical": return "電気設備"
        case "plumbing": return "配管設備"
        case "hvac": return "空調設備"
        case "elevator": return "エレベーター"
        case "security": return "セキュリティ"
        case "fire": return "消防設備"
        default: return cat
        }
    }

    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.accentBlue).frame(width: 20)
            Text(label).font(.subheadline).foregroundColor(.textGray)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
        }
        Divider()
    }
}

struct UpdateEquipmentStatusView: View {
    @ObservedObject var vm: EquipmentViewModel
    let equipment: Equipment
    @Environment(\.dismiss) private var dismiss

    @State private var status: String
    @State private var lastMaintenance = Date()
    @State private var nextMaintenance = Date()
    @State private var notes: String
    @State private var useLastDate = false
    @State private var useNextDate = false

    init(vm: EquipmentViewModel, equipment: Equipment) {
        self.vm = vm
        self.equipment = equipment
        _status = State(initialValue: equipment.status)
        _notes = State(initialValue: equipment.notes ?? "")
    }

    let statuses = [("active","正常"), ("maintenance","メンテナンス中"), ("broken","故障"), ("inactive","停止中")]

    var body: some View {
        NavigationStack {
            Form {
                Section("ステータス") {
                    Picker("状態", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                }
                Section("メンテナンス記録") {
                    Toggle("最終メンテナンス日を記録", isOn: $useLastDate)
                    if useLastDate { DatePicker("最終メンテナンス", selection: $lastMaintenance, displayedComponents: .date) }
                    Toggle("次回メンテナンス日を設定", isOn: $useNextDate)
                    if useNextDate { DatePicker("次回メンテナンス", selection: $nextMaintenance, displayedComponents: .date) }
                }
                Section("メモ") {
                    TextEditor(text: $notes).frame(height: 80)
                }
            }
            .navigationTitle("ステータス更新")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            let fmt = ISO8601DateFormatter()
                            let success = await vm.updateEquipment(
                                equipment.id,
                                status: status,
                                lastMaintenanceDate: useLastDate ? fmt.string(from: lastMaintenance) : nil,
                                nextMaintenanceDate: useNextDate ? fmt.string(from: nextMaintenance) : nil,
                                notes: notes.isEmpty ? nil : notes
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
    }
}

struct FloorDetailView: View {
    let floor: Int
    let equipment: [Equipment]

    var body: some View {
        List(equipment.filter { _ in true }) { equip in
            NavigationLink { EquipmentDetailView(equipment: equip) } label: {
                EquipmentRow(equipment: equip, vm: EquipmentViewModel())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("\(floor)階の設備")
    }
}

struct RoomEquipmentDetailView: View {
    let room: Room
    let equipment: [Equipment]

    var body: some View {
        List(equipment.filter { $0.roomId == room.id }) { equip in
            NavigationLink { EquipmentDetailView(equipment: equip) } label: {
                EquipmentRow(equipment: equip, vm: EquipmentViewModel())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("\(room.roomNumber)の設備")
    }
}
