import SwiftUI

struct PublicLandDetailView: View {
    let land: Land

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailImageView(url: land.thumbnailUrl, height: 250)

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(land.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textDark)
                        Spacer()
                        StatusBadge(status: land.status, type: .land)
                    }

                    Label(land.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.textGray)

                    Divider()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        PropertyDetailItem(label: "面積", value: "\(String(format: "%.1f", land.area))㎡", icon: "square.dashed")
                        if let zoning = land.zoning {
                            PropertyDetailItem(label: "用途地域", value: zoning, icon: "map")
                        }
                    }

                    Divider()

                    if let value = land.currentValue {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("評価額")
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

                    if let notes = land.notes, !notes.isEmpty {
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
        .navigationTitle("土地詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100_000_000 { return String(format: "%.1f億円", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万円", value / 10_000) }
        return "¥\(Int(value))"
    }
}
