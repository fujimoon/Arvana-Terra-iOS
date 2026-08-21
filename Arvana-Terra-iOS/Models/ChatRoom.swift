import Foundation

struct ChatRoom: Codable, Identifiable {
    let id: String
    let name: String
    let roomType: String
    let propertyId: String?
    let landId: String?
    let participantIds: [String]
    let lastMessage: String?
    let lastMessageAt: String?
    let unreadCount: Int?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case roomType
        case propertyId
        case landId
        case participantIds
        case lastMessage
        case lastMessageAt
        case unreadCount
        case createdAt
        case updatedAt
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatRoomId: String
    let senderId: String
    let senderName: String
    let content: String
    let messageType: String
    let fileUrl: String?
    let isRead: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case chatRoomId
        case senderId
        case senderName
        case content
        case messageType
        case fileUrl
        case isRead
        case createdAt
    }
}

struct SendMessageRequest: Codable {
    let content: String
    let messageType: String
}

struct CreateChatRoomRequest: Codable {
    let name: String
    let roomType: String
    let propertyId: String?
    let landId: String?
    let participantIds: [String]
}
