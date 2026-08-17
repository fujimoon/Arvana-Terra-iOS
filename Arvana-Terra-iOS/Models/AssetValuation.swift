import Foundation

struct AssetValuation: Codable, Identifiable {
    let id: String
    let propertyId: String?
    let landId: String?
    let valuationType: String
    let estimatedValue: Double
    let marketValue: Double?
    let incomeApproach: Double?
    let costApproach: Double?
    let valuationDate: String
    let appraiserName: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case propertyId
        case landId
        case valuationType
        case estimatedValue
        case marketValue
        case incomeApproach
        case costApproach
        case valuationDate
        case appraiserName
        case notes
        case createdAt
        case updatedAt
    }
}

struct CalculateValuationRequest: Codable {
    let propertyId: String?
    let landId: String?
    let area: Double
    let location: String
    let buildingType: String?
    let yearBuilt: Int?
    let condition: String?
}

struct CalculateValuationResponse: Codable {
    let estimatedValue: Double
    let marketValue: Double
    let incomeApproach: Double?
    let costApproach: Double?
    let confidence: String
    let factors: [String: Double]
}
