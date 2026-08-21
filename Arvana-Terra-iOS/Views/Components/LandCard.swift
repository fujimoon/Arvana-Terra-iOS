import SwiftUI

struct LandCard: View {
    let land: Land

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThumbnailImageView(url: land.thumbnailUrl, height: 140)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(land.name)
                        .font(.headline)
                        .foregroundColor(.textDark)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(status: land.status, type: .land)
                }

                Label(land.address, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.textGray)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("面積")
                            .font(.caption2)
                            .foregroundColor(.textGray)
                        Text("\(String(format: "%.1f", land.area))㎡")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textDark)
                    }

                    if let zoning = land.zoning {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("用途地域")
                                .font(.caption2)
                                .foregroundColor(.textGray)
                            Text(zoning)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textDark)
                        }
                    }

                    Spacer()

                    if let value = land.currentValue {
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

                if land.isPublic {
                    HStack {
                        Spacer()
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

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100_000_000 {
            return String(format: "%.1f億円", value / 100_000_000)
        } else if value >= 10_000 {
            return String(format: "%.0f万円", value / 10_000)
        }
        return "¥\(Int(value))"
    }
}
