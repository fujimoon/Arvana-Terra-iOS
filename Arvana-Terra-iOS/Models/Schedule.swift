import Foundation
import SwiftUI

struct Schedule: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var description: String?
    var startDateTime: String
    var endDateTime: String
    var isAllDay: Bool
    var category: String
    var color: String?
    var relatedPropertyId: String?
    var relatedLandId: String?
    var relatedRoomId: String?
    var relatedTenantId: String?
    var reminderMinutes: Int?
    var isCompleted: Bool
    var isCancelled: Bool
    let createdAt: String
    let updatedAt: String
    var relatedProperty: RelatedEntity?
    var relatedLand: RelatedEntity?
    var relatedRoom: RelatedEntity?
    var relatedTenant: RelatedEntity?

    struct RelatedEntity: Codable {
        let id: String
        let name: String
    }

    var categoryLabel: String {
        ScheduleCategory(rawValue: category)?.label ?? "その他"
    }

    var categoryColor: Color {
        ScheduleCategory(rawValue: category)?.color ?? Color(hex: "#6B7280")
    }

    var startDate: Date? {
        ISO8601DateFormatter().date(from: startDateTime)
    }
}

enum ScheduleCategory: String, CaseIterable {
    case inspection, contract, maintenance, payment, move_in, move_out, other

    var label: String {
        switch self {
        case .inspection:  return "内見・点検"
        case .contract:    return "契約"
        case .maintenance: return "メンテナンス"
        case .payment:     return "入金・支払"
        case .move_in:     return "入居"
        case .move_out:    return "退去"
        case .other:       return "その他"
        }
    }

    var color: Color {
        switch self {
        case .inspection:  return Color(hex: "#4A90D9")
        case .contract:    return Color(hex: "#1B3A6B")
        case .maintenance: return Color(hex: "#F59E0B")
        case .payment:     return Color(hex: "#10B981")
        case .move_in:     return Color(hex: "#8B5CF6")
        case .move_out:    return Color(hex: "#EC4899")
        case .other:       return Color(hex: "#6B7280")
        }
    }
}
