import SwiftUI

struct PublicPropertyDetailView: View {
    let property: Property
    @State private var showingInquiry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image gallery
                if !property.imageUrls.isEmpty {
                    TabView {
                        ForEach(property.imageUrls, id: \.self) { urlStr in
                            if let url = URL(string: urlStr) {
                                AsyncImage(url: url) { img in
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.borderGray
                                }
                                .clipped()
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 260)
                } else {
                    Rectangle()
                        .fill(Color.borderGray)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "house.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color.textGray)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title & price
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(Color.textDark)
                        Text(property.address)
                            .font(.subheadline)
                            .foregroundColor(Color.textGray)
                        if let price = property.price {
                            Text("\(Int(price / 10000))万円")
                                .font(.title3).fontWeight(.bold)
                                .foregroundColor(Color.primaryNavy)
                                .padding(.top, 4)
                        }
                    }

                    Divider()

                    // Status badge
                    HStack {
                        Text("状態")
                            .font(.subheadline)
                            .foregroundColor(Color.textGray)
                        Spacer()
                        StatusBadge(status: property.status)
                    }

                    Divider()

                    // Description
                    if let desc = property.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("物件詳細")
                                .font(.headline)
                                .foregroundColor(Color.textDark)
                            Text(desc)
                                .font(.body)
                                .foregroundColor(Color.textGray)
                        }
                        Divider()
                    }

                    // Inquiry button
                    Button {
                        showingInquiry = true
                    } label: {
                        Text("購入・相談のお問い合わせ")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryNavy)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .sheet(isPresented: $showingInquiry) {
                        PropertyInquiryView(propertyId: property.id, propertyName: property.name)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(property.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatusBadge: View {
    let status: String

    var label: String {
        switch status {
        case "draft": return "下書き"
        case "for_sale": return "売り出し中"
        case "sold": return "売却済"
        case "pending": return "審査中"
        case "approved": return "承認済"
        case "rejected": return "否認"
        case "replied": return "返信済"
        case "closed": return "クローズ"
        default: return status
        }
    }

    var color: Color {
        switch status {
        case "for_sale", "approved": return Color.successGreen
        case "sold", "closed": return Color.textGray
        case "draft", "pending": return Color.warningOrange
        case "rejected": return Color.errorRed
        case "replied": return Color.accentBlue
        default: return Color.textGray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption).fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}
