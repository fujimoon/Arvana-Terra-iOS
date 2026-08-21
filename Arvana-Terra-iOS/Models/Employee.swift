import Foundation

struct Employee: Codable, Identifiable {
    let id: String
    let ownerId: String
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var role: String?
    var department: String?
    var hireDate: String?
    var contractType: String? // "full_time", "part_time", "contract", "temp"
    var mynumber: String?     // バックエンドで複号済み・マスク表示
    var mynumberVerified: Bool
    var notes: String?
    var isActive: Bool
    let createdAt: String
    let updatedAt: String
}
