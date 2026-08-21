import Foundation
import Combine

// MARK: - Socket Events
enum SocketEvent: String {
    case connect = "connect"
    case disconnect = "disconnect"
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case newMessage = "new_message"
    case sendMessage = "send_message"
    case typing = "typing"
    case stopTyping = "stop_typing"
    case error = "error"
}

// MARK: - Socket Message
struct SocketMessage: Codable {
    let event: String
    let data: SocketData?
}

struct SocketData: Codable {
    let roomId: String?
    let message: ChatMessage?
    let userId: String?
    let text: String?
    let error: String?
}

// MARK: - SocketService
@MainActor
class SocketService: ObservableObject {
    static let shared = SocketService()

    @Published var isConnected = false
    @Published var receivedMessage: ChatMessage?
    @Published var typingUsers: Set<String> = []

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var currentRoomId: String?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var pingTimer: Timer?
    private var eioSid: String?

    private let messageSubject = PassthroughSubject<ChatMessage, Never>()
    var messagePublisher: AnyPublisher<ChatMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    private init() {
        self.session = URLSession(configuration: .default)
    }

    // MARK: - Connection Management
    func connect(token: String) {
        guard !isConnected else { return }

        // Socket.IO EIO4 handshake
        guard let url = URL(string: "\(AppConfig.wsURL)/socket.io/?EIO=4&transport=websocket&token=\(token)") else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        // Send EIO4 open handshake
        sendRaw("40")

        isConnected = true
        reconnectAttempts = 0
        startPingTimer()
        receiveMessages()
    }

    func disconnect() {
        stopPingTimer()
        if let roomId = currentRoomId {
            leaveRoom(roomId: roomId)
        }
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        currentRoomId = nil
    }

    // MARK: - Room Management
    func joinRoom(roomId: String) {
        currentRoomId = roomId
        let payload = "{\"roomId\":\"\(roomId)\"}"
        sendSocketIOEvent(event: SocketEvent.joinRoom.rawValue, data: payload)
    }

    func leaveRoom(roomId: String) {
        let payload = "{\"roomId\":\"\(roomId)\"}"
        sendSocketIOEvent(event: SocketEvent.leaveRoom.rawValue, data: payload)
        if currentRoomId == roomId {
            currentRoomId = nil
        }
    }

    // MARK: - Messaging
    func sendMessage(roomId: String, content: String) {
        let escapedContent = content.replacingOccurrences(of: "\"", with: "\\\"")
        let payload = "{\"roomId\":\"\(roomId)\",\"content\":\"\(escapedContent)\",\"messageType\":\"text\"}"
        sendSocketIOEvent(event: SocketEvent.sendMessage.rawValue, data: payload)
    }

    func sendTyping(roomId: String) {
        let payload = "{\"roomId\":\"\(roomId)\"}"
        sendSocketIOEvent(event: SocketEvent.typing.rawValue, data: payload)
    }

    func sendStopTyping(roomId: String) {
        let payload = "{\"roomId\":\"\(roomId)\"}"
        sendSocketIOEvent(event: SocketEvent.stopTyping.rawValue, data: payload)
    }

    // MARK: - Private Helpers
    private func sendSocketIOEvent(event: String, data: String) {
        // EIO4 Socket.IO event format: 42["event", data]
        let message = "42[\"\(event)\",\(data)]"
        sendRaw(message)
    }

    private func sendRaw(_ text: String) {
        webSocketTask?.send(.string(text)) { [weak self] error in
            if let error = error {
                print("SocketService: Send error - \(error.localizedDescription)")
                Task { @MainActor [weak self] in
                    self?.handleDisconnect()
                }
            }
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleRawMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleRawMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveMessages()

                case .failure(let error):
                    print("SocketService: Receive error - \(error.localizedDescription)")
                    self.handleDisconnect()
                }
            }
        }
    }

    private func handleRawMessage(_ text: String) {
        // EIO4 protocol parsing
        // "0" = open, "2" = ping, "3" = pong, "40" = connect, "42" = event
        if text == "2" {
            // Ping - respond with pong
            sendRaw("3")
            return
        }

        if text.hasPrefix("40") {
            // Socket.IO connected
            return
        }

        if text.hasPrefix("42") {
            parseSocketIOEvent(text)
        }
    }

    private func parseSocketIOEvent(_ text: String) {
        // Format: 42["event",{...data...}]
        let payload = String(text.dropFirst(2))

        guard payload.hasPrefix("["),
              let data = payload.data(using: .utf8) else { return }

        do {
            if let array = try JSONSerialization.jsonObject(with: data) as? [Any],
               array.count >= 2,
               let eventName = array[0] as? String {

                switch eventName {
                case SocketEvent.newMessage.rawValue:
                    if let messageData = array[1] as? [String: Any],
                       let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
                       let message = try? JSONDecoder().decode(ChatMessage.self, from: jsonData) {
                        receivedMessage = message
                        messageSubject.send(message)
                    }

                case SocketEvent.typing.rawValue:
                    if let data = array[1] as? [String: Any],
                       let userId = data["userId"] as? String {
                        typingUsers.insert(userId)
                    }

                case SocketEvent.stopTyping.rawValue:
                    if let data = array[1] as? [String: Any],
                       let userId = data["userId"] as? String {
                        typingUsers.remove(userId)
                    }

                case SocketEvent.error.rawValue:
                    print("SocketService: Socket error received")

                default:
                    break
                }
            }
        } catch {
            print("SocketService: Parse error - \(error.localizedDescription)")
        }
    }

    private func handleDisconnect() {
        isConnected = false
        stopPingTimer()

        guard reconnectAttempts < maxReconnectAttempts else {
            print("SocketService: Max reconnect attempts reached")
            return
        }

        reconnectAttempts += 1
        let delay = Double(reconnectAttempts) * 2.0
        print("SocketService: Reconnecting in \(delay)s (attempt \(reconnectAttempts))")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self,
                  let token = UserDefaults.standard.string(forKey: "accessToken") else { return }
            self.connect(token: token)
        }
    }

    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendRaw("2")
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}
