import SwiftUI

struct PropertyManageView: View {
    let property: Property
    @ObservedObject var viewModel: PropertyViewModel
    @State private var showingSaleRequest = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                    .frame(height: 240)
                } else {
                    Rectangle()
                        .fill(Color.borderGray)
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "house.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.textGray)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Status
                    HStack {
                        Text("ステータス").foregroundColor(Color.textGray)
                        Spacer()
                        StatusBadge(status: property.status)
                    }

                    Divider()

                    // Address
                    VStack(alignment: .leading, spacing: 4) {
                        Text("住所").font(.caption).foregroundColor(Color.textGray)
                        Text(property.address).foregroundColor(Color.textDark)
                    }

                    if let price = property.price {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("価格").font(.caption).foregroundColor(Color.textGray)
                            Text("\(Int(price / 10000))万円")
                                .font(.headline).foregroundColor(Color.primaryNavy)
                        }
                    }

                    if let desc = property.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("説明").font(.caption).foregroundColor(Color.textGray)
                            Text(desc).foregroundColor(Color.textDark)
                        }
                    }

                    Divider()

                    // Chat link
                    NavigationLink(destination: ChatListView(type: "property", targetId: property.id, targetName: property.name)) {
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
                        PropertySaleRequestView(
                            propertyId: property.id,
                            propertyName: property.name,
                            thumbnailUrl: property.thumbnailUrl
                        )
                    }

                    // Delete button
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteProperty(property.id)
                            dismiss()
                        }
                    } label: {
                        Label("この物件を削除", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.errorRed)
                }
                .padding()
            }
        }
        .navigationTitle(property.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
