import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var messages: [ChatMessage] = []
    @Published var currentRoomId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var messageText = ""
    @Published var typingUsers: Set<String> = []

    private let apiService = APIService.shared
    private let socketService = SocketService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSocketListeners()
    }

    private func setupSocketListeners() {
        socketService.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                if message.chatRoomId == self.currentRoomId {
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                    }
                }
                // Update chat room last message
                if let idx = self.chatRooms.firstIndex(where: { $0.id == message.chatRoomId }) {
                    // Re-fetch room to update last message
                    Task { await self.fetchChatRooms() }
                }
            }
            .store(in: &cancellables)
    }

    func fetchChatRooms() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            chatRooms = try await apiService.getChatRooms()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMessages(roomId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            messages = try await apiService.getChatMessages(roomId: roomId)
            currentRoomId = roomId
            socketService.joinRoom(roomId: roomId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() async {
        guard let roomId = currentRoomId, !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let content = messageText
        messageText = ""

        // Send via socket for real-time
        socketService.sendMessage(roomId: roomId, content: content)

        // Also send via REST for persistence
        do {
            let message = try await apiService.sendMessage(roomId: roomId, content: content)
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        } catch {
            print("ChatViewModel: Failed to send via REST - \(error.localizedDescription)")
        }
    }

    func leaveCurrentRoom() {
        if let roomId = currentRoomId {
            socketService.leaveRoom(roomId: roomId)
            currentRoomId = nil
        }
    }

    func createChatRoom(name: String, roomType: String, propertyId: String?, landId: String?, participantIds: [String]) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreateChatRoomRequest(
                name: name, roomType: roomType,
                propertyId: propertyId, landId: landId,
                participantIds: participantIds
            )
            let newRoom = try await apiService.createChatRoom(request)
            chatRooms.insert(newRoom, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func sendTyping() {
        guard let roomId = currentRoomId else { return }
        socketService.sendTyping(roomId: roomId)
    }

    func sendStopTyping() {
        guard let roomId = currentRoomId else { return }
        socketService.sendStopTyping(roomId: roomId)
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}
