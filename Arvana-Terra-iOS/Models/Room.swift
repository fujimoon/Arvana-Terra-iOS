import Foundation

struct Room: Codable, Identifiable {
    let id: String
    let propertyId: String
    let roomNumber: String
    let floor: Int
    let area: Double
    let roomType: String
    let status: String
    let rentPrice: Double?
    let occupantName: String?
    let occupantContact: String?
    let contractStartDate: String?
    let contractEndDate: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case propertyId
        case roomNumber
        case floor
        case area
        case roomType
        case status
        case rentPrice
        case occupantName
        case occupantContact
        case contractStartDate
        case contractEndDate
        case notes
        case createdAt
        case updatedAt
    }
}

struct Tenant: Codable, Identifiable {
    let id: String
    let roomId: String
    let name: String
    let nameKana: String?
    let email: String?
    let phone: String?
    let birthDate: String?
    let gender: String?
    let occupation: String?
    let workplace: String?
    let workplacePhone: String?
    let annualIncome: Int?
    let emergencyContactName: String?
    let emergencyContactPhone: String?
    let moveInDate: String?
    let moveOutDate: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String
}

struct FamilyMember: Codable, Identifiable {
    let id: String
    let tenantId: String
    let name: String
    let relationship: String
    let birthDate: String?
    let notes: String?
}

struct CreateRoomRequest: Codable {
    let propertyId: String
    let roomNumber: String
    let floor: Int
    let area: Double
    let roomType: String
    let status: String
    let rentPrice: Double?
    let notes: String?
}

struct UpdateRoomRequest: Codable {
    let roomNumber: String?
    let floor: Int?
    let area: Double?
    let roomType: String?
    let status: String?
    let rentPrice: Double?
    let occupantName: String?
    let occupantContact: String?
    let contractStartDate: String?
    let contractEndDate: String?
    let notes: String?
}
