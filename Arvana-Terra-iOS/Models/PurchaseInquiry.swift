import Foundation

struct PurchaseInquiry: Codable, Identifiable {
    let id: String
    let type: String // "property" or "land"
    let propertyId: String?
    let landId: String?
    let senderName: String
    let senderEmail: String
    let senderPhone: String?
    let inquiryType: String // "purchase" or "consultation"
    let message: String
    let status: String // "pending", "replied", "closed"
    let adminNote: String?
    let createdAt: String
}

struct InquiryRequest: Codable {
    let type: String
    let propertyId: String?
    let landId: String?
    let senderName: String
    let senderEmail: String
    let senderPhone: String?
    let inquiryType: String
    let message: String
}
