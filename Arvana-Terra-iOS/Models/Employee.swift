import Foundation

struct Employee: Codable, Identifiable {
    let id: String
    let userId: String?
    let name: String
    let email: String
    let phoneNumber: String?
    let department: String?
    let position: String?
    let employmentType: String?
    let startDate: String?
    let salary: Double?
    let status: String
    let avatarUrl: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case email
        case phoneNumber
        case department
        case position
        case employmentType
        case startDate
        case salary
        case status
        case avatarUrl
        case notes
        case createdAt
        case updatedAt
    }
}
