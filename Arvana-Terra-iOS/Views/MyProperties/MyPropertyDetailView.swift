import SwiftUI

struct MyPropertyDetailView: View {
    let property: Property
    @State private var showManage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailImageView(url: property.thumbnailUrl, height: 250)

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(property.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textDark)
                        Spacer()
                        StatusBadge(status: property.status, type: .property)
                    }

                    Label(property.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.textGray)

                    Divider()

                    // Key metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        PropertyDetailItem(label: "建物種別", value: buildingTypeLabel(property.buildingType), icon: "building.2")
                        PropertyDetailItem(label: "延床面積", value: "\(String(format: "%.1f", property.area))㎡", icon: "square.dashed")
                        PropertyDetailItem(label: "階数", value: "\(property.floors)階建て", icon: "stairs")
                        PropertyDetailItem(label: "総部屋数", value: "\(property.totalRooms)室", icon: "door.left.hand.open")
                        if let price = property.purchasePrice {
                            PropertyDetailItem(label: "購入価格", value: formatCurrency(price), icon: "yensign.circle")
                        }
                        if let value = property.currentValue {
                            PropertyDetailItem(label: "現在評価額", value: formatCurrency(value), icon: "chart.line.uptrend.xyaxis")
                        }
                    }

                    Divider()

                    // Navigation links
                    VStack(spacing: 12) {
                        NavigationLink {
                            PropertyManageView(property: property)
                        } label: {
                            ManagementLinkRow(icon: "wrench.and.screwdriver.fill", title: "物件管理", subtitle: "部屋・設備・タスクの管理", color: .primaryNavy)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            RoomOccupancyView(property: property)
                        } label: {
                            ManagementLinkRow(icon: "person.fill.checkmark", title: "入居状況", subtitle: "部屋の空室・入居状況", color: .secondaryBlue)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            PropertyChatListView(property: property)
                        } label: {
                            ManagementLinkRow(icon: "message.fill", title: "チャット", subtitle: "テナント・スタッフとのやり取り", color: .accentBlue)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ContractListView()
                        } label: {
                            ManagementLinkRow(icon: "doc.text.fill", title: "契約管理", subtitle: "賃貸・売買契約の管理", color: .successGreen)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ValuationView()
                        } label: {
                            ManagementLinkRow(icon: "chart.bar.fill", title: "資産評価", subtitle: "物件の評価額シミュレーション", color: .warningOrange)
                        }
                        .buttonStyle(.plain)
                    }

                    if let notes = property.notes, !notes.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("備考")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textGray)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.textDark)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.backgroundGray)
        .navigationTitle("物件詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showManage = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.primaryNavy)
                }
            }
        }
        .sheet(isPresented: $showManage) {
            EditPropertyView(property: property)
        }
    }

    private func buildingTypeLabel(_ type: String) -> String {
        switch type {
        case "apartment": return "マンション"
        case "house": return "一戸建て"
        case "office": return "オフィス"
        case "commercial": return "商業施設"
        case "warehouse": return "倉庫"
        default: return type
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100_000_000 { return String(format: "%.1f億円", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万円", value / 10_000) }
        return "¥\(Int(value))"
    }
}

struct ManagementLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(color)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textDark)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textGray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textGray)
        }
        .padding(14)
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EditPropertyView: View {
    let property: Property
    @StateObject private var vm = PropertyViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address: String
    @State private var status: String
    @State private var isPublic: Bool
    @State private var currentValue: String
    @State private var notes: String

    init(property: Property) {
        self.property = property
        _name = State(initialValue: property.name)
        _address = State(initialValue: property.address)
        _status = State(initialValue: property.status)
        _isPublic = State(initialValue: property.isPublic)
        _currentValue = State(initialValue: property.currentValue.map { String($0) } ?? "")
        _notes = State(initialValue: property.notes ?? "")
    }

    let statuses = [("owned", "所有中"), ("for_sale", "売却中"), ("rented", "賃貸中"), ("vacant", "空き"), ("under_construction", "建設中")]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("物件名", text: $name)
                    TextField("住所", text: $address)
                }
                Section("ステータス") {
                    Picker("状態", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Toggle("公開する", isOn: $isPublic)
                }
                Section("評価額") {
                    TextField("現在評価額 (円)", text: $currentValue).keyboardType(.decimalPad)
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 100)
                }
            }
            .navigationTitle("物件を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            let success = await vm.updateProperty(
                                property.id, name: name, address: address,
                                status: status, isPublic: isPublic,
                                currentValue: Double(currentValue),
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
