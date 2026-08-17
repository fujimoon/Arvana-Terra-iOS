import SwiftUI

struct RoomListView: View {
    let property: Property
    let rooms: [Room]
    @StateObject private var vm = PropertyViewModel()
    @State private var showAdd = false
    @State private var selectedFloor: Int?

    var floors: [Int] { Array(Set(rooms.map { $0.floor })).sorted() }

    var filteredRooms: [Room] {
        guard let floor = selectedFloor else { return rooms }
        return rooms.filter { $0.floor == floor }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !floors.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "全階", isSelected: selectedFloor == nil) {
                            selectedFloor = nil
                        }
                        ForEach(floors, id: \.self) { floor in
                            FilterChip(title: "\(floor)階", isSelected: selectedFloor == floor) {
                                selectedFloor = floor
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.surfaceWhite)
            }

            if filteredRooms.isEmpty {
                EmptyStateView(
                    title: "部屋なし",
                    message: "部屋を追加してください",
                    systemImage: "door.left.hand.open",
                    actionTitle: "部屋を追加",
                    action: { showAdd = true }
                )
            } else {
                List {
                    ForEach(filteredRooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room)
                        } label: {
                            RoomRow(room: room)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("部屋一覧")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddRoomView(vm: vm, propertyId: property.id)
        }
    }
}

struct RoomRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 2) {
                Text("\(room.floor)F")
                    .font(.caption2).fontWeight(.bold).foregroundColor(.accentBlue)
                Text(room.roomNumber)
                    .font(.caption).foregroundColor(.textGray)
            }
            .frame(width: 40)
            .padding(8)
            .background(Color.accentBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(roomTypeLabel(room.roomType))
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                Text("\(String(format: "%.1f", room.area))㎡")
                    .font(.caption).foregroundColor(.textGray)
                if let rent = room.rentPrice {
                    Text(formatCurrency(rent) + "/月")
                        .font(.caption).foregroundColor(.primaryNavy)
                }
            }
            Spacer()
            StatusBadge(status: room.status, type: .room)
        }
    }

    func roomTypeLabel(_ type: String) -> String {
        switch type {
        case "residence": return "居住用"
        case "office": return "オフィス"
        case "store": return "店舗"
        case "warehouse": return "倉庫"
        case "parking": return "駐車場"
        default: return type
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return "¥" + (formatter.string(from: NSNumber(value: value)) ?? "0")
    }
}

struct AddRoomView: View {
    @ObservedObject var vm: PropertyViewModel
    let propertyId: String
    @Environment(\.dismiss) private var dismiss

    @State private var roomNumber = ""
    @State private var floor = "1"
    @State private var area = ""
    @State private var roomType = "residence"
    @State private var status = "vacant"
    @State private var rentPrice = ""
    @State private var notes = ""

    let roomTypes = [("residence","居住用"), ("office","オフィス"), ("store","店舗"), ("warehouse","倉庫"), ("parking","駐車場")]
    let statuses = [("vacant","空室"), ("occupied","入居中"), ("reserved","予約済"), ("maintenance","メンテナンス")]

    var isValid: Bool { !roomNumber.isEmpty && !area.isEmpty && Double(area) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("部屋情報") {
                    TextField("部屋番号 *", text: $roomNumber)
                    TextField("階数 *", text: $floor).keyboardType(.numberPad)
                    TextField("面積 (㎡) *", text: $area).keyboardType(.decimalPad)
                    Picker("部屋タイプ", selection: $roomType) {
                        ForEach(roomTypes, id: \.0) { Text($0.1).tag($0.0) }
                    }
                }
                Section("ステータス・賃料") {
                    Picker("状態", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    TextField("賃料 (円/月)", text: $rentPrice).keyboardType(.decimalPad)
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 80)
                }
            }
            .navigationTitle("部屋を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        // Implementation via APIService directly
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
