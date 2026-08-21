import Foundation

struct Property: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let description: String?
    let price: Double?
    let status: String // "draft", "for_sale", "sold"
    let isPublic: Bool
    let thumbnailUrl: String?
    let imageUrls: [String]
    let ownerId: String
    let createdAt: String
    let updatedAt: String
}

struct CreatePropertyRequest: Codable {
    let name: String
    let address: String
    let description: String?
    let price: Double?
}
