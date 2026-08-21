import Foundation

struct Vendor: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let contactName: String?
    let email: String?
    let phoneNumber: String?
    let address: String?
    let website: String?
    let rating: Double?
    let status: String
    let isPublic: Bool
    let description: String?
    let certifications: [String]
    let specialties: [String]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case contactName
        case email
        case phoneNumber
        case address
        case website
        case rating
        case status
        case isPublic
        case description
        case certifications
        case specialties
        case createdAt
        case updatedAt
    }
}
