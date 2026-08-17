import SwiftUI

struct PropertyChatListView: View {
    let property: Property
    @StateObject private var vm = ChatViewModel()
    @State private var showCreateChat = false

    var body: some View {
        Group {
            if vm.isLoading && vm.chatRooms.isEmpty {
                LoadingView()
            } else if vm.chatRooms.isEmpty {
                EmptyStateView(
                    title: "チャットルームなし",
                    message: "新しいチャットルームを作成してください",
                    systemImage: "message",
                    actionTitle: "チャットルームを作成",
                    action: { showCreateChat = true }
                )
            } else {
                List(vm.chatRooms.filter { $0.propertyId == property.id }) { room in
                    NavigationLink {
                        PropertyChatRoomView(chatRoom: room)
                    } label: {
                        ChatRoomRow(room: room)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("\(property.name) チャット")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateChat = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchChatRooms() }
        .sheet(isPresented: $showCreateChat) {
            CreateChatRoomView(vm: vm, propertyId: property.id)
        }
    }
}

struct PropertyChatRoomView: View {
    let chatRoom: ChatRoom

    var body: some View {
        ChatRoomView(chatRoom: chatRoom)
    }
}

struct ChatRoomRow: View {
    let room: ChatRoom

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentBlue.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "message.fill")
                        .foregroundColor(.accentBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textDark)
                if let lastMessage = room.lastMessage {
                    Text(lastMessage)
                        .font(.caption)
                        .foregroundColor(.textGray)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let lastAt = room.lastMessageAt {
                Text(formatTime(lastAt))
                    .font(.caption2)
                    .foregroundColor(.textGray)
            }
        }
    }

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        let now = Date()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let f = DateFormatter()
            f.dateFormat = "M/d"
            f.locale = Locale(identifier: "ja_JP")
            return f.string(from: date)
        }
    }
}

struct CreateChatRoomView: View {
    @ObservedObject var vm: ChatViewModel
    var propertyId: String? = nil
    var landId: String? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var roomType = "property"

    var body: some View {
        NavigationStack {
            Form {
                Section("チャットルーム情報") {
                    TextField("ルーム名", text: $name)
                    Picker("タイプ", selection: $roomType) {
                        Text("物件").tag("property")
                        Text("土地").tag("land")
                        Text("一般").tag("general")
                        Text("従業員").tag("employee")
                    }
                }
            }
            .navigationTitle("チャットルームを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        Task {
                            let success = await vm.createChatRoom(
                                name: name, roomType: roomType,
                                propertyId: propertyId, landId: landId,
                                participantIds: []
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(name.isEmpty || vm.isLoading)
                }
            }
        }
    }
}
