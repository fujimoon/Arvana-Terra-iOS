import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let role: String
    let avatarUrl: String?
    let phoneNumber: String?
    let companyName: String?
    let isActive: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case role
        case avatarUrl
        case phoneNumber
        case companyName
        case isActive
        case createdAt
        case updatedAt
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
    let role: String?
    let companyName: String?
    let phoneNumber: String?
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
