import Foundation

struct Payment: Codable, Identifiable {
    let id: String
    let propertyId: String
    let roomId: String
    let tenantId: String?
    let amount: Double
    let dueDate: String
    let paidDate: String?
    let status: String
    let notes: String?
    let createdAt: String
    let updatedAt: String
    let room: PaymentRoomSummary?
    let tenant: PaymentTenantSummary?
}

struct PaymentRoomSummary: Codable {
    let id: String
    let roomNumber: String
}

struct PaymentTenantSummary: Codable {
    let id: String
    let name: String
}

struct CreatePaymentRequest: Codable {
    let roomId: String
    let tenantId: String?
    let amount: Double
    let dueDate: String
    let paidDate: String?
    let status: String
    let notes: String?
}
