import Foundation

struct Contract: Codable, Identifiable {
    let id: String
    let propertyId: String?
    let landId: String?
    let roomId: String?
    let contractType: String
    let tenantName: String
    let tenantContact: String?
    let tenantEmail: String?
    let startDate: String
    let endDate: String
    let rentAmount: Double?
    let depositAmount: Double?
    let status: String
    let documentUrl: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case propertyId
        case landId
        case roomId
        case contractType
        case tenantName
        case tenantContact
        case tenantEmail
        case startDate
        case endDate
        case rentAmount
        case depositAmount
        case status
        case documentUrl
        case notes
        case createdAt
        case updatedAt
    }
}

struct CreateContractRequest: Codable {
    let propertyId: String?
    let landId: String?
    let roomId: String?
    let contractType: String
    let tenantName: String
    let tenantContact: String?
    let tenantEmail: String?
    let startDate: String
    let endDate: String
    let rentAmount: Double?
    let depositAmount: Double?
    let notes: String?
}

struct UpdateContractRequest: Codable {
    let tenantName: String?
    let tenantContact: String?
    let tenantEmail: String?
    let startDate: String?
    let endDate: String?
    let rentAmount: Double?
    let depositAmount: Double?
    let status: String?
    let notes: String?
}
