import SwiftUI

struct EquipmentManageView: View {
    let property: Property
    @StateObject private var vm = EquipmentViewModel()
    @State private var showAdd = false
    @State private var selectedCategory: String?

    var filteredEquipment: [Equipment] {
        guard let cat = selectedCategory else { return vm.equipmentList }
        return vm.equipmentList.filter { $0.category == cat }
    }

    var categories: [String] {
        Array(Set(vm.equipmentList.map { $0.category })).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "すべて", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(categories, id: \.self) { cat in
                            FilterChip(title: categoryLabel(cat), isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.surfaceWhite)
            }

            if vm.isLoading {
                LoadingView()
            } else if filteredEquipment.isEmpty {
                EmptyStateView(
                    title: "設備なし",
                    message: "設備を追加してください",
                    systemImage: "wrench.and.screwdriver",
                    actionTitle: "設備を追加",
                    action: { showAdd = true }
                )
            } else {
                List {
                    ForEach(filteredEquipment) { equip in
                        NavigationLink {
                            EquipmentDetailView(equipment: equip)
                        } label: {
                            EquipmentRow(equipment: equip, vm: vm)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("設備管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchEquipment(propertyId: property.id) }
        .sheet(isPresented: $showAdd) {
            AddEquipmentView(vm: vm, propertyId: property.id)
        }
    }

    func categoryLabel(_ cat: String) -> String {
        switch cat {
        case "electrical": return "電気"
        case "plumbing": return "配管"
        case "hvac": return "空調"
        case "elevator": return "EV"
        case "security": return "防犯"
        case "fire": return "消防"
        default: return cat
        }
    }
}

struct EquipmentRow: View {
    let equipment: Equipment
    @ObservedObject var vm: EquipmentViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(vm.statusColor(for: equipment.status).opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: categoryIcon(equipment.category))
                        .foregroundColor(vm.statusColor(for: equipment.status))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                if let mfr = equipment.manufacturer {
                    Text(mfr).font(.caption).foregroundColor(.textGray)
                }
                if let next = equipment.nextMaintenanceDate {
                    Label("次回: \(formatDate(next))", systemImage: "wrench.fill")
                        .font(.caption).foregroundColor(.warningOrange)
                }
            }
            Spacer()
            StatusBadge(status: equipment.status, type: .equipment)
        }
    }

    func categoryIcon(_ cat: String) -> String {
        switch cat {
        case "electrical": return "bolt.fill"
        case "plumbing": return "drop.fill"
        case "hvac": return "wind"
        case "elevator": return "arrow.up.and.down.square"
        case "security": return "lock.shield.fill"
        case "fire": return "flame.fill"
        default: return "wrench.fill"
        }
    }

    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy/M/d"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .textDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryNavy : Color.backgroundGray)
                .clipShape(Capsule())
        }
    }
}

struct AddEquipmentView: View {
    @ObservedObject var vm: EquipmentViewModel
    let propertyId: String
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "electrical"
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var status = "active"
    @State private var installationDate = Date()
    @State private var warrantyExpiry = Date()
    @State private var notes = ""
    @State private var useWarrantyDate = false
    @State private var useInstallDate = false

    let categories = [("electrical","電気"), ("plumbing","配管"), ("hvac","空調"), ("elevator","EV"), ("security","防犯"), ("fire","消防"), ("other","その他")]
    let statuses = [("active","正常"), ("maintenance","メンテナンス中"), ("broken","故障"), ("inactive","停止中")]

    var isValid: Bool { !name.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("設備名 *", text: $name)
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Picker("状態", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                }
                Section("メーカー情報") {
                    TextField("メーカー", text: $manufacturer)
                    TextField("型番", text: $model)
                }
                Section("日付") {
                    Toggle("設置日を設定", isOn: $useInstallDate)
                    if useInstallDate { DatePicker("設置日", selection: $installationDate, displayedComponents: .date) }
                    Toggle("保証期限を設定", isOn: $useWarrantyDate)
                    if useWarrantyDate { DatePicker("保証期限", selection: $warrantyExpiry, displayedComponents: .date) }
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 80)
                }
            }
            .navigationTitle("設備を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let fmt = ISO8601DateFormatter()
                            let success = await vm.createEquipment(
                                propertyId: propertyId, roomId: nil,
                                name: name, category: category,
                                manufacturer: manufacturer.isEmpty ? nil : manufacturer,
                                model: model.isEmpty ? nil : model,
                                status: status,
                                installationDate: useInstallDate ? fmt.string(from: installationDate) : nil,
                                warrantyExpiry: useWarrantyDate ? fmt.string(from: warrantyExpiry) : nil,
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
