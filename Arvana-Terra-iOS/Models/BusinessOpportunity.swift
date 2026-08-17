import Foundation

struct BusinessOpportunity: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let opportunityType: String
    let location: String?
    let budget: Double?
    let expectedReturn: Double?
    let riskLevel: String
    let status: String
    let deadline: String?
    let postedById: String?
    let postedByName: String?
    let tags: [String]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case opportunityType
        case location
        case budget
        case expectedReturn
        case riskLevel
        case status
        case deadline
        case postedById
        case postedByName
        case tags
        case createdAt
        case updatedAt
    }
}
