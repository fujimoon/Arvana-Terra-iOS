import SwiftUI

struct ChatRoomView: View {
    let chatRoom: ChatRoom
    @StateObject private var vm = ChatViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isTyping = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if vm.isLoading && vm.messages.isEmpty {
                            InlineLoadingView()
                        }

                        ForEach(vm.sortedMessages) { message in
                            ChatBubble(
                                message: message,
                                currentUserId: authVM.currentUser?.id ?? ""
                            )
                            .id(message.id)
                        }

                        if !vm.typingUsers.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { idx in
                                    Circle()
                                        .fill(Color.textGray)
                                        .frame(width: 6, height: 6)
                                        .offset(y: idx % 2 == 0 ? -2 : 2)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(Color.backgroundGray)
                .onTapGesture { inputFocused = false }
                .onChange(of: vm.sortedMessages.count) { _ in
                    if let lastMessage = vm.sortedMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 10) {
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                }

                ZStack(alignment: .leading) {
                    if vm.messageText.isEmpty {
                        Text("メッセージを入力...")
                            .font(.body)
                            .foregroundColor(.textGray)
                            .padding(.horizontal, 4)
                    }
                    TextField("", text: $vm.messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .focused($inputFocused)
                        .onChange(of: vm.messageText) { _ in
                            if !vm.messageText.isEmpty {
                                vm.sendTyping()
                            } else {
                                vm.sendStopTyping()
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.backgroundGray)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Button(action: {
                    Task { await vm.sendMessage() }
                    inputFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(vm.messageText.isEmpty ? .textGray : .primaryNavy)
                }
                .disabled(vm.messageText.isEmpty || vm.isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.surfaceWhite)
        }
        .navigationTitle(chatRoom.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(SocketService.shared.isConnected ? Color.successGreen : Color.errorRed)
                        .frame(width: 8, height: 8)
                    Text(SocketService.shared.isConnected ? "接続中" : "切断")
                        .font(.caption)
                        .foregroundColor(SocketService.shared.isConnected ? .successGreen : .errorRed)
                }
            }
        }
        .task {
            await vm.fetchMessages(roomId: chatRoom.id)
        }
        .onDisappear {
            vm.leaveCurrentRoom()
        }
    }
}
