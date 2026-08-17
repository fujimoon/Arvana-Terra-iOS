import SwiftUI

struct PropertyManageView: View {
    let property: Property
    @StateObject private var propertyVM = PropertyViewModel()
    @StateObject private var equipVM = EquipmentViewModel()
    @StateObject private var taskVM = TaskViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Property summary header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(.headline)
                            .foregroundColor(.textDark)
                        Text(property.address)
                            .font(.caption)
                            .foregroundColor(.textGray)
                    }
                    Spacer()
                    StatusBadge(status: property.status, type: .property)
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Rooms section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("部屋管理")
                            .font(.headline)
                            .foregroundColor(.textDark)
                        Spacer()
                        NavigationLink("詳細") {
                            RoomListView(property: property, rooms: propertyVM.rooms)
                        }
                        .font(.caption)
                        .foregroundColor(.accentBlue)
                    }

                    HStack(spacing: 12) {
                        RoomStatBadge(
                            count: propertyVM.rooms.filter { $0.status == "occupied" }.count,
                            label: "入居中",
                            color: .successGreen
                        )
                        RoomStatBadge(
                            count: propertyVM.rooms.filter { $0.status == "vacant" }.count,
                            label: "空室",
                            color: .accentBlue
                        )
                        RoomStatBadge(
                            count: propertyVM.rooms.filter { $0.status == "maintenance" }.count,
                            label: "メンテ",
                            color: .warningOrange
                        )
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Equipment section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("設備管理")
                            .font(.headline)
                            .foregroundColor(.textDark)
                        Spacer()
                        NavigationLink("詳細") {
                            EquipmentManageView(property: property)
                        }
                        .font(.caption)
                        .foregroundColor(.accentBlue)
                    }

                    if equipVM.equipmentList.isEmpty {
                        Text("設備が登録されていません")
                            .font(.caption)
                            .foregroundColor(.textGray)
                    } else {
                        ForEach(equipVM.equipmentList.prefix(3)) { equip in
                            HStack {
                                Circle()
                                    .fill(equipVM.statusColor(for: equip.status).opacity(0.15))
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().fill(equipVM.statusColor(for: equip.status)).frame(width: 8, height: 8))
                                Text(equip.name)
                                    .font(.subheadline)
                                    .foregroundColor(.textDark)
                                Spacer()
                                StatusBadge(status: equip.status, type: .equipment)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Tasks section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("タスク")
                            .font(.headline)
                            .foregroundColor(.textDark)
                        Spacer()
                        NavigationLink("詳細") {
                            TaskManageView()
                        }
                        .font(.caption)
                        .foregroundColor(.accentBlue)
                    }

                    if taskVM.tasks.isEmpty {
                        Text("タスクが登録されていません")
                            .font(.caption)
                            .foregroundColor(.textGray)
                    } else {
                        ForEach(taskVM.pendingTasks.prefix(3)) { task in
                            TaskRowView(task: task)
                        }
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("物件管理")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let r1: () = propertyVM.fetchRooms(propertyId: property.id)
            async let r2: () = equipVM.fetchEquipment(propertyId: property.id)
            async let r3: () = taskVM.fetchTasks(propertyId: property.id)
            _ = await (r1, r2, r3)
        }
    }
}

struct RoomStatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.textGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
