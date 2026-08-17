import SwiftUI

struct PublicPropertyDetailView: View {
    let property: Property

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Images
                ThumbnailImageView(url: property.thumbnailUrl, height: 250)

                VStack(alignment: .leading, spacing: 20) {
                    // Title and status
                    HStack {
                        Text(property.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textDark)
                        Spacer()
                        StatusBadge(status: property.status, type: .property)
                    }

                    // Address
                    Label(property.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.textGray)

                    Divider()

                    // Property details grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        PropertyDetailItem(label: "建物種別", value: buildingTypeLabel(property.buildingType), icon: "building.2")
                        PropertyDetailItem(label: "延床面積", value: "\(String(format: "%.1f", property.area))㎡", icon: "square.dashed")
                        PropertyDetailItem(label: "階数", value: "\(property.floors)階建て", icon: "stairs")
                        PropertyDetailItem(label: "総部屋数", value: "\(property.totalRooms)室", icon: "door.left.hand.open")
                    }

                    Divider()

                    // Valuation
                    if let value = property.currentValue {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("資産評価額")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textGray)
                            Text(formatCurrency(value))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryNavy)
                        }
                        Divider()
                    }

                    // Notes
                    if let notes = property.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("備考")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textGray)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.textDark)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.backgroundGray)
        .navigationTitle("物件詳細")
        .navigationBarTitleDisplayMode(.inline)
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
        if value >= 100_000_000 { return String(format: "%.1f億円", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万円", value / 10_000) }
        return "¥\(Int(value))"
    }
}

struct PropertyDetailItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.textGray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textDark)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundGray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
