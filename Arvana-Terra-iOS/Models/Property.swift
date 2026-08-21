import Foundation

struct Property: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let buildingType: String
    let floors: Int
    let totalRooms: Int
    let area: Double
    let status: String
    let isPublic: Bool?
    let thumbnailUrl: String?
    let imageUrls: [String]?
    let purchasePrice: Double?
    let currentValue: Double?
    let notes: String?
    let ownerId: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case buildingType
        case floors
        case totalRooms
        case area
        case status
        case isPublic
        case thumbnailUrl
        case imageUrls
        case purchasePrice
        case currentValue
        case notes
        case ownerId
        case createdAt
        case updatedAt
    }
}

struct CreatePropertyRequest: Codable {
    let name: String
    let address: String
    let buildingType: String
    let floors: Int
    let totalRooms: Int
    let area: Double
    let status: String
    let isPublic: Bool
    let purchasePrice: Double?
    let notes: String?
}

struct UpdatePropertyRequest: Codable {
    let name: String?
    let address: String?
    let buildingType: String?
    let floors: Int?
    let totalRooms: Int?
    let area: Double?
    let status: String?
    let isPublic: Bool?
    let currentValue: Double?
    let notes: String?
}
