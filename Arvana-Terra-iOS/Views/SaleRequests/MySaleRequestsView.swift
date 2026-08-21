import SwiftUI

struct MySaleRequestsView: View {
    @StateObject private var viewModel = SaleRequestViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.mySaleRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 48))
                            .foregroundColor(Color.borderGray)
                        Text("売出し申請はまだありません")
                            .foregroundColor(Color.textGray)
                        Text("物件・土地管理画面から申請できます")
                            .font(.caption)
                            .foregroundColor(Color.textGray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.mySaleRequests) { request in
                        SaleRequestRowView(request: request)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("売出し申請")
            .refreshable {
                await viewModel.loadMySaleRequests()
            }
        }
        .task {
            await viewModel.loadMySaleRequests()
        }
    }
}

struct SaleRequestRowView: View {
    let request: SaleListingRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Thumbnail
                if let urlStr = request.thumbnailUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.borderGray
                    }
                    .frame(width: 50, height: 50).cornerRadius(6).clipped()
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.borderGray)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: request.type == "land" ? "map" : "house")
                                .foregroundColor(Color.textGray)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(request.type == "land" ? "土地" : "物件")
                            .font(.caption).fontWeight(.medium)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentBlue.opacity(0.15))
                            .foregroundColor(Color.accentBlue)
                            .cornerRadius(4)
                        Spacer()
                        StatusBadge(status: request.status)
                    }

                    if let price = request.askingPrice {
                        Text("希望価格: \(Int(price / 10000))万円")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(Color.primaryNavy)
                    }
                }
            }

            if let adminNote = request.adminNote, !adminNote.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption)
                        .foregroundColor(request.status == "rejected" ? Color.errorRed : Color.accentBlue)
                    Text(adminNote)
                        .font(.caption)
                        .foregroundColor(Color.textGray)
                }
                .padding(8)
                .background(Color.backgroundLight)
                .cornerRadius(6)
            }

            Text(formatDate(request.createdAt))
                .font(.caption2)
                .foregroundColor(Color.textGray)
        }
        .padding(.vertical, 4)
    }

    func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            let display = DateFormatter()
            display.dateFormat = "yyyy/MM/dd HH:mm"
            display.locale = Locale(identifier: "ja_JP")
            return display.string(from: date)
        }
        return dateStr
    }
}
