import SwiftUI

enum StatusBadgeType {
    case property
    case land
    case contract
    case task
    case equipment
    case room
    case generic
}

struct StatusBadge: View {
    let status: String
    var type: StatusBadgeType = .generic

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var label: String {
        switch type {
        case .property, .land:
            return propertyLandLabel
        case .contract:
            return contractLabel
        case .task:
            return taskLabel
        case .equipment:
            return equipmentLabel
        case .room:
            return roomLabel
        case .generic:
            return status
        }
    }

    private var propertyLandLabel: String {
        switch status {
        case "owned": return "所有中"
        case "for_sale": return "売却中"
        case "rented": return "賃貸中"
        case "vacant": return "空き"
        case "under_construction": return "建設中"
        case "under_renovation": return "改装中"
        default: return status
        }
    }

    private var contractLabel: String {
        switch status {
        case "active": return "有効"
        case "expired": return "期限切れ"
        case "terminated": return "解除"
        case "pending": return "保留中"
        default: return status
        }
    }

    private var taskLabel: String {
        switch status {
        case "pending": return "未着手"
        case "in_progress": return "進行中"
        case "completed": return "完了"
        case "cancelled": return "キャンセル"
        default: return status
        }
    }

    private var equipmentLabel: String {
        switch status {
        case "active", "normal": return "正常"
        case "maintenance": return "メンテナンス中"
        case "broken": return "故障"
        case "inactive": return "停止中"
        default: return status
        }
    }

    private var roomLabel: String {
        switch status {
        case "occupied": return "入居中"
        case "vacant": return "空室"
        case "reserved": return "予約済"
        case "maintenance": return "メンテナンス"
        default: return status
        }
    }

    private var color: Color {
        switch status {
        case "active", "occupied", "owned", "normal", "completed":
            return .successGreen
        case "maintenance", "pending", "in_progress", "for_sale", "reserved":
            return .warningOrange
        case "broken", "expired", "terminated", "cancelled", "inactive":
            return .errorRed
        case "vacant", "under_construction", "under_renovation":
            return .accentBlue
        default:
            return .textGray
        }
    }
}
