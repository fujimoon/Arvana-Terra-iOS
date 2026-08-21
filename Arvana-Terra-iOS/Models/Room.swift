import Foundation

struct Room: Codable, Identifiable {
    let id: String
    let propertyId: String
    var name: String
    var floor: Int?
    var area: Double?
    var roomType: String?
    var rentAmount: Double?
    var status: String // "vacant", "occupied", "maintenance"
    var notes: String?
    let createdAt: String
    let updatedAt: String
    var tenants: [Tenant]?
    var payments: [Payment]?
    var parkingSpots: [ParkingSpot]?

    var statusLabel: String {
        switch status {
        case "vacant": return "空室"
        case "occupied": return "入居中"
        case "maintenance": return "メンテナンス"
        default: return status
        }
    }
}

struct ParkingSpot: Codable, Identifiable {
    let id: String
    let roomId: String
    var spotNumber: String
    var isOccupied: Bool
}

struct Tenant: Codable, Identifiable {
    let id: String
    let roomId: String
    var name: String
    var nameKana: String?
    var email: String?
    var phone: String?
    var birthDate: String?
    var gender: String?
    var occupation: String?
    var workplace: String?
    var workplacePhone: String?
    var annualIncome: Double?
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var emergencyContactRelationship: String?
    var moveInDate: String?
    var moveOutDate: String?
    var contractStartDate: String?
    var contractEndDate: String?
    var rentAmount: Double?
    var depositAmount: Double?
    var keyMoneyAmount: Double?
    var parkingUsed: Bool
    var parkingSpotNumber: String?
    var licensePlateNumber: String?
    var paymentStatus: String // "current", "overdue", "partial"
    var status: String // "active", "moved_out"
    var notes: String?
    let createdAt: String
    let updatedAt: String
    var familyMembers: [FamilyMember]?
    var payments: [Payment]?

    var paymentStatusLabel: String {
        switch paymentStatus {
        case "current": return "正常"
        case "overdue": return "滞納"
        case "partial": return "一部未払"
        default: return paymentStatus
        }
    }
}

struct FamilyMember: Codable, Identifiable {
    let id: String
    let tenantId: String
    var name: String
    var nameKana: String?
    var relationship: String
    var birthDate: String?
    var gender: String?
    var occupation: String?
    var notes: String?
}

struct Payment: Codable, Identifiable {
    let id: String
    let tenantId: String
    let roomId: String
    var amount: Double
    var dueDate: String
    var paidDate: String?
    var status: String // "pending", "paid", "overdue", "partial"
    var paymentMethod: String?
    var note: String?

    var statusLabel: String {
        switch status {
        case "paid": return "支払済"
        case "pending": return "未払"
        case "overdue": return "滞納"
        case "partial": return "一部未払"
        default: return status
        }
    }
}
