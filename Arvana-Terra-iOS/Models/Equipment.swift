import Foundation

struct Equipment: Codable, Identifiable {
    let id: String
    let propertyId: String
    let roomId: String?
    let name: String
    let category: String
    let manufacturer: String?
    let model: String?
    let serialNumber: String?
    let installationDate: String?
    let warrantyExpiry: String?
    let status: String
    let lastMaintenanceDate: String?
    let nextMaintenanceDate: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case propertyId
        case roomId
        case name
        case category
        case manufacturer
        case model
        case serialNumber
        case installationDate
        case warrantyExpiry
        case status
        case lastMaintenanceDate
        case nextMaintenanceDate
        case notes
        case createdAt
        case updatedAt
    }
}

struct CreateEquipmentRequest: Codable {
    let propertyId: String
    let roomId: String?
    let name: String
    let category: String
    let manufacturer: String?
    let model: String?
    let serialNumber: String?
    let installationDate: String?
    let warrantyExpiry: String?
    let status: String
    let notes: String?
}

struct UpdateEquipmentRequest: Codable {
    let name: String?
    let category: String?
    let manufacturer: String?
    let model: String?
    let serialNumber: String?
    let status: String?
    let lastMaintenanceDate: String?
    let nextMaintenanceDate: String?
    let notes: String?
}

struct SmartDevice: Codable, Identifiable {
    let id: String
    let equipmentId: String
    let deviceType: String
    let deviceName: String
    let isOnline: Bool
    let currentValue: String?
    let unit: String?
    let lastUpdated: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case equipmentId
        case deviceType
        case deviceName
        case isOnline
        case currentValue
        case unit
        case lastUpdated
        case createdAt
        case updatedAt
    }
}
