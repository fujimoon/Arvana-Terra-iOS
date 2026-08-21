import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let phone: String?
    let role: String // "homeowner", "landlord", "admin"
    let createdAt: String
}

struct AuthResponse: Codable {
    let token: String
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
    let phone: String?
    let role: String
}
