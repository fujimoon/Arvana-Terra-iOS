import SwiftUI

struct RoomListView: View {
    let propertyId: String
    let propertyName: String

    @State private var rooms: [Room] = []
    @State private var isLoading = true
    @State private var showingAddRoom = false

    var vacantCount: Int { rooms.filter { $0.status == "vacant" }.count }
    var occupiedCount: Int { rooms.filter { $0.status == "occupied" }.count }
    var overdueCount: Int {
        rooms.filter { room in
            room.tenants?.contains { $0.paymentStatus == "overdue" || $0.paymentStatus == "partial" } ?? false
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Row
                HStack(spacing: 12) {
                    SummaryCard(title: "空室", count: vacantCount, color: .green)
                    SummaryCard(title: "入居中", count: occupiedCount, color: Color(hex: "#1B3A6B"))
                    SummaryCard(title: "滞納中", count: overdueCount, color: .red)
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if rooms.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("部屋がまだ登録されていません")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(rooms) { room in
                            NavigationLink(destination: RoomDetailView(roomId: room.id)) {
                                RoomCard(room: room)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("部屋管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddRoom = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRoom) {
            RoomFormView(propertyId: propertyId) { _ in
                Task { await loadRooms() }
            }
        }
        .task { await loadRooms() }
    }

    private func loadRooms() async {
        isLoading = true
        defer { isLoading = false }
        rooms = (try? await RoomService.shared.getRoomsByProperty(propertyId: propertyId)) ?? []
    }
}

struct SummaryCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct RoomCard: View {
    let room: Room
    var activeTenant: Tenant? { room.tenants?.first { $0.status == "active" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.name)
                    .font(.headline)
                    .foregroundColor(Color(hex: "#1B3A6B"))
                Spacer()
                StatusBadge(
                    status: room.status,
                    label: room.statusLabel,
                    color: room.status == "vacant" ? .green : room.status == "occupied" ? Color(hex: "#1B3A6B") : .orange
                )
            }

            if let type = room.roomType {
                Text(type + (room.area.map { " / \(Int($0))m2" } ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            if let rent = room.rentAmount {
                Text("¥\(Int(rent).formatted())/月")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let tenant = activeTenant {
                Divider()
                Text(tenant.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if tenant.paymentStatus != "current" {
                    Text(tenant.paymentStatusLabel)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(tenant.paymentStatus == "overdue" ? Color.red.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundColor(tenant.paymentStatus == "overdue" ? .red : .orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: String
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}
