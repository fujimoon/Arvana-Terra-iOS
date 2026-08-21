import Foundation

struct SaleListingRequest: Codable, Identifiable {
    let id: String
    let type: String // "property" or "land"
    let propertyId: String?
    let landId: String?
    let ownerId: String
    let askingPrice: Double?
    let description: String?
    let contactInfo: String?
    let thumbnailUrl: String?
    let imageUrls: [String]
    let status: String // "pending", "approved", "rejected"
    let adminNote: String?
    let approvedAt: String?
    let rejectedAt: String?
    let createdAt: String
}
