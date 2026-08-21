import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let notificationType: String
    let relatedId: String?
    let relatedType: String?
    let isRead: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case title
        case body
        case notificationType
        case relatedId
        case relatedType
        case isRead
        case createdAt
    }
}
