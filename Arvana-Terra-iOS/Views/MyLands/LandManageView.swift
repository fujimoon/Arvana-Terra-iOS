import SwiftUI

struct LandManageView: View {
    let land: Land
    @ObservedObject var viewModel: LandViewModel
    @State private var showingSaleRequest = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                    .frame(height: 240)
                } else {
                    Rectangle()
                        .fill(Color.borderGray)
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "map.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.textGray)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Status
                    HStack {
                        Text("ステータス").foregroundColor(Color.textGray)
                        Spacer()
                        StatusBadge(status: land.status)
                    }

                    Divider()

                    // Address
                    VStack(alignment: .leading, spacing: 4) {
                        Text("住所").font(.caption).foregroundColor(Color.textGray)
                        Text(land.address).foregroundColor(Color.textDark)
                    }

                    if let price = land.price {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("価格").font(.caption).foregroundColor(Color.textGray)
                            Text("\(Int(price / 10000))万円")
                                .font(.headline).foregroundColor(Color.primaryNavy)
                        }
                    }

                    if let desc = land.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("説明").font(.caption).foregroundColor(Color.textGray)
                            Text(desc).foregroundColor(Color.textDark)
                        }
                    }

                    Divider()

                    // Chat link
                    NavigationLink(destination: ChatListView(type: "land", targetId: land.id, targetName: land.name)) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .foregroundColor(Color.primaryNavy)
                            Text("チャット")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.primaryNavy)

                    // Sale request button
                    Button {
                        showingSaleRequest = true
                    } label: {
                        Label("売出し希望を申請", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.secondaryBlue)
                    .sheet(isPresented: $showingSaleRequest) {
                        LandSaleRequestView(
                            landId: land.id,
                            landName: land.name,
                            thumbnailUrl: land.thumbnailUrl
                        )
                    }

                    // Delete button
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteLand(land.id)
                            dismiss()
                        }
                    } label: {
                        Label("この土地を削除", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.errorRed)
                }
                .padding()
            }
        }
        .navigationTitle(land.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
