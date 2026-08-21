import Foundation

struct ChatRoom: Codable, Identifiable {
    let id: String
    let type: String // "land" | "property" | "employee"
    let title: String
    let description: String?
    let landId: String?
    let propertyId: String?
    let employeeId: String?
    let createdById: String
    let createdBy: ChatUserRef
    let messages: [ChatMessage]
    let count: ChatRoomCount
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, description
        case landId, propertyId, employeeId
        case createdById, createdBy, messages
        case count = "_count"
        case createdAt, updatedAt
    }
}

struct ChatRoomCount: Codable {
    let messages: Int
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let chatRoomId: String
    let senderId: String
    let sender: ChatUserRef
    let content: String
    let createdAt: String
}

struct ChatUserRef: Codable {
    let id: String
    let name: String
}

struct ChatMessagesResponse: Codable {
    let messages: [ChatMessage]
    let total: Int
    let page: Int
    let limit: Int
}

struct CreateChatRoomRequest: Codable {
    let type: String
    let title: String
    let description: String?
    let landId: String?
    let propertyId: String?
    let employeeId: String?
}
