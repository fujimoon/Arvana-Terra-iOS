import SwiftUI

// MARK: - チャットルーム一覧画面
struct ChatListView: View {
    let type: String        // "land" | "property" | "employee"
    let targetId: String
    let targetName: String

    @State private var rooms: [ChatRoom] = []
    @State private var isLoading = true
    @State private var showCreate = false
    @State private var errorMessage = ""

    var typeLabel: String {
        switch type {
        case "land": return "土地"
        case "property": return "物件"
        case "employee": return "従業員"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if rooms.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(Color.gray.opacity(0.4))
                    Text("チャットルームがありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("「＋ 新規トピック」から作成してください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                List(rooms) { room in
                    NavigationLink(destination: ChatRoomView(room: room)) {
                        ChatRoomRowView(room: room)
                    }
                }
                .listStyle(.plain)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle("\(typeLabel)チャット")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateChatRoomSheet(type: type, targetId: targetId) { newRoom in
                rooms.insert(newRoom, at: 0)
            }
        }
        .task {
            await loadRooms()
        }
    }

    func loadRooms() async {
        isLoading = true
        errorMessage = ""
        do {
            rooms = try await ChatService.shared.getChatRooms(type: type, targetId: targetId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - チャットルーム行
struct ChatRoomRowView: View {
    let room: ChatRoom

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(room.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                if let lastMsg = room.messages.first {
                    Text(relativeTime(lastMsg.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            if let desc = room.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            if let lastMsg = room.messages.first {
                Text("\(lastMsg.sender.name): \(lastMsg.content)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("メッセージなし")
                    .font(.caption)
                    .foregroundColor(Color.gray.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }

    func relativeTime(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 86400 {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: date)
    }
}

// MARK: - チャットルーム作成シート
struct CreateChatRoomSheet: View {
    let type: String
    let targetId: String
    let onCreated: (ChatRoom) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("トピック情報") {
                    TextField("トピック名（必須）", text: $title)
                    TextField("説明（任意）", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("新規チャットルーム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        Task { await createRoom() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
    }

    func createRoom() async {
        isLoading = true
        errorMessage = ""
        do {
            let room = try await ChatService.shared.createChatRoom(
                type: type,
                title: title,
                description: description.isEmpty ? nil : description,
                targetId: targetId
            )
            onCreated(room)
            dismiss()
        } catch {
            errorMessage = "作成に失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
