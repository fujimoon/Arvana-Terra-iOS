import SwiftUI

struct RoomDetailView: View {
    let room: Room
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("部屋 \(room.roomNumber)")
                            .font(.title2).fontWeight(.bold).foregroundColor(.textDark)
                        Text("\(room.floor)階 · \(roomTypeLabel(room.roomType))")
                            .font(.subheadline).foregroundColor(.textGray)
                    }
                    Spacer()
                    StatusBadge(status: room.status, type: .room)
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Details
                VStack(spacing: 12) {
                    DetailRow(label: "面積", value: "\(String(format: "%.1f", room.area))㎡", icon: "square.dashed")
                    if let rent = room.rentPrice {
                        DetailRow(label: "賃料", value: formatCurrency(rent) + "/月", icon: "yensign.circle")
                    }
                    if let name = room.occupantName {
                        DetailRow(label: "入居者", value: name, icon: "person.fill")
                    }
                    if let contact = room.occupantContact {
                        DetailRow(label: "連絡先", value: contact, icon: "phone.fill")
                    }
                    if let start = room.contractStartDate {
                        DetailRow(label: "契約開始", value: formatDate(start), icon: "calendar")
                    }
                    if let end = room.contractEndDate {
                        DetailRow(label: "契約終了", value: formatDate(end), icon: "calendar.badge.exclamationmark")
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let notes = room.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備考").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        Text(notes).font(.body).foregroundColor(.textDark)
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("部屋詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) {
                    Image(systemName: "pencil").foregroundColor(.primaryNavy)
                }
            }
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
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return "¥" + (f.string(from: NSNumber(value: value)) ?? "0")
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct RoomOccupancyView: View {
    let property: Property
    @StateObject private var vm = PropertyViewModel()

    var vacantRooms: [Room] { vm.rooms.filter { $0.status == "vacant" } }
    var occupiedRooms: [Room] { vm.rooms.filter { $0.status == "occupied" } }
    var maintenanceRooms: [Room] { vm.rooms.filter { $0.status == "maintenance" } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Occupancy summary
                VStack(spacing: 4) {
                    Text("稼働率")
                        .font(.subheadline).foregroundColor(.textGray)
                    Text("\(Int(vm.occupancyRate))%")
                        .font(.system(size: 52, weight: .bold)).foregroundColor(.primaryNavy)

                    HStack(spacing: 20) {
                        OccupancyStat(value: occupiedRooms.count, label: "入居中", color: .successGreen)
                        OccupancyStat(value: vacantRooms.count, label: "空室", color: .accentBlue)
                        OccupancyStat(value: maintenanceRooms.count, label: "メンテ", color: .warningOrange)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Room grid by floor
                let floors = Array(Set(vm.rooms.map { $0.floor })).sorted()
                ForEach(floors, id: \.self) { floor in
                    let floorRooms = vm.rooms.filter { $0.floor == floor }.sorted { $0.roomNumber < $1.roomNumber }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(floor)階 (\(floorRooms.count)室)")
                            .font(.headline).foregroundColor(.textDark)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(floorRooms) { room in
                                NavigationLink {
                                    RoomDetailView(room: room)
                                } label: {
                                    RoomGridCell(room: room)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("入居状況")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchRooms(propertyId: property.id) }
    }
}

struct OccupancyStat: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.title2).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.textGray)
        }
    }
}

struct RoomGridCell: View {
    let room: Room

    var cellColor: Color {
        switch room.status {
        case "occupied": return .successGreen
        case "vacant": return .accentBlue
        case "maintenance": return .warningOrange
        case "reserved": return .secondaryBlue
        default: return .textGray
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(room.roomNumber)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(cellColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
