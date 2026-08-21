import Foundation

struct UserPreference: Codable {
    let id: String
    let userId: String
    var displayMode: String // "nationwide" または "regional"
    var displayPrefectures: [String]
    var preferredRegions: [String]
}
