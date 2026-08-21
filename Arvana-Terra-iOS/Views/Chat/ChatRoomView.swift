import SwiftUI

// MARK: - チャットルーム画面（HTTPポーリング方式）
struct ChatRoomView: View {
    let room: ChatRoom

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var pollingTask: Task<Void, Never>? = nil

    var currentUserId: String {
        UserDefaults.standard.string(forKey: "userId") ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // メッセージリスト
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else if messages.isEmpty {
                            Text("メッセージはまだありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(messages) { msg in
                                MessageBubbleView(
                                    message: msg,
                                    isMe: msg.senderId == currentUserId
                                )
                                .id(msg.id)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // 入力エリア
            HStack(spacing: 8) {
                TextField("メッセージを入力...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending
                                ? .gray
                                : Color.primaryNavy
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle(room.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - メッセージ読み込み
    func loadMessages() async {
        do {
            let loaded = try await ChatService.shared.getMessages(roomId: room.id)
            await MainActor.run {
                messages = loaded
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    // MARK: - メッセージ送信
    func sendMessage() async {
        let content = inputText.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        inputText = ""
        isSending = true
        do {
            let msg = try await ChatService.shared.sendMessage(roomId: room.id, content: content)
            await MainActor.run {
                if !messages.contains(where: { $0.id == msg.id }) {
                    messages.append(msg)
                }
            }
        } catch {}
        isSending = false
    }

    // MARK: - ポーリング開始（3秒間隔）
    func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if Task.isCancelled { break }
                await pollNewMessages()
            }
        }
    }

    // MARK: - ポーリング停止
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - 新着メッセージ取得
    func pollNewMessages() async {
        do {
            let latest = try await ChatService.shared.getMessages(roomId: room.id)
            await MainActor.run {
                let existingIds = Set(messages.map(\.id))
                let newMsgs = latest.filter { !existingIds.contains($0.id) }
                if !newMsgs.isEmpty {
                    messages.append(contentsOf: newMsgs)
                }
            }
        } catch {}
    }
}

// MARK: - メッセージバブル
struct MessageBubbleView: View {
    let message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isMe { Spacer(minLength: 48) }

            if !isMe {
                Circle()
                    .fill(Color.primaryNavy.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(message.sender.name.prefix(1)))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.primaryNavy)
                    )
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                if !isMe {
                    Text(message.sender.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMe ? Color.primaryNavy : Color(.systemGray6))
                    .foregroundColor(isMe ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isMe { Spacer(minLength: 48) }
        }
    }

    func formatTime(_ dateStr: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = f.date(from: dateStr) else { return "" }
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}
