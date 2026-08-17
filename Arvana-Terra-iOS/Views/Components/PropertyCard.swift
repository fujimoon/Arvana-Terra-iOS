import SwiftUI

struct PropertyCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThumbnailImageView(url: property.thumbnailUrl, height: 160)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(property.name)
                        .font(.headline)
                        .foregroundColor(.textDark)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(status: property.status, type: .property)
                }

                Label(property.address, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.textGray)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("延床面積")
                            .font(.caption2)
                            .foregroundColor(.textGray)
                        Text("\(String(format: "%.1f", property.area))㎡")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textDark)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("階数")
                            .font(.caption2)
                            .foregroundColor(.textGray)
                        Text("\(property.floors)階")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textDark)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("部屋数")
                            .font(.caption2)
                            .foregroundColor(.textGray)
                        Text("\(property.totalRooms)室")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textDark)
                    }

                    Spacer()

                    if let value = property.currentValue {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("評価額")
                                .font(.caption2)
                                .foregroundColor(.textGray)
                            Text(formatCurrency(value))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryNavy)
                        }
                    }
                }
                .padding(.top, 4)

                HStack {
                    Label(buildingTypeLabel(property.buildingType), systemImage: "building.2")
                        .font(.caption)
                        .foregroundColor(.accentBlue)
                    Spacer()
                    if property.isPublic {
                        Label("公開中", systemImage: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.successGreen)
                    }
                }
            }
            .padding(12)
        }
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    private func buildingTypeLabel(_ type: String) -> String {
        switch type {
        case "apartment": return "マンション"
        case "house": return "一戸建て"
        case "office": return "オフィス"
        case "commercial": return "商業施設"
        case "warehouse": return "倉庫"
        default: return type
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100_000_000 {
            return String(format: "%.1f億円", value / 100_000_000)
        } else if value >= 10_000 {
            return String(format: "%.0f万円", value / 10_000)
        }
        return "¥\(Int(value))"
    }
}
