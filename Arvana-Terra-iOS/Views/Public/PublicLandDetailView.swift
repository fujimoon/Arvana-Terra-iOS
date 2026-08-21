import SwiftUI

struct PublicLandDetailView: View {
    let land: Land
    @State private var showingInquiry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Image gallery
                if !land.imageUrls.isEmpty {
                    TabView {
                        ForEach(land.imageUrls, id: \.self) { urlStr in
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
                            Image(systemName: "map.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color.textGray)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title & price
                    VStack(alignment: .leading, spacing: 4) {
                        Text(land.name)
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(Color.textDark)
                        Text(land.address)
                            .font(.subheadline)
                            .foregroundColor(Color.textGray)
                        if let price = land.price {
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
                        StatusBadge(status: land.status)
                    }

                    Divider()

                    // Description
                    if let desc = land.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("土地詳細")
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
                        LandInquiryView(landId: land.id, landName: land.name)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(land.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
