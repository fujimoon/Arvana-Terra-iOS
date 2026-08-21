import SwiftUI

struct PublicPropertyListView: View {
    @StateObject private var viewModel = PropertyViewModel()
    @ObservedObject var regionManager = RegionModeManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 地域モードバナー
                if regionManager.isRegionalMode {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("地域モード: \(regionManager.displayPrefectures.joined(separator: "・"))")
                            .font(.caption)
                        Spacer()
                        Button("全国") { regionManager.toggleMode() }
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(8)
                    .background(Color.primaryNavy.opacity(0.1))
                    .foregroundColor(Color.primaryNavy)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                Group {
                    if viewModel.isLoading {
                        ProgressView("読み込み中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.publicProperties.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "house.slash")
                                .font(.system(size: 48))
                                .foregroundColor(Color.borderGray)
                            Text("現在、売り出し中の物件はありません")
                                .foregroundColor(Color.textGray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(viewModel.publicProperties) { property in
                            NavigationLink(destination: PublicPropertyDetailView(property: property)) {
                                PropertyRowView(property: property)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("売り出し中の物件")
            .refreshable {
                await viewModel.loadPublicProperties()
            }
        }
        .task {
            await viewModel.loadPublicProperties()
        }
    }
}

struct PropertyRowView: View {
    let property: Property

    var body: some View {
        HStack(spacing: 12) {
            if let urlStr = property.thumbnailUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.borderGray
                }
                .frame(width: 70, height: 70)
                .cornerRadius(8)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.borderGray)
                    .frame(width: 70, height: 70)
                    .overlay(Image(systemName: "house").foregroundColor(Color.textGray))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(property.name)
                    .font(.headline)
                    .foregroundColor(Color.textDark)
                    .lineLimit(1)
                Text(property.address)
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                    .lineLimit(1)
                if let price = property.price {
                    Text("\(Int(price / 10000))万円")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.primaryNavy)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
