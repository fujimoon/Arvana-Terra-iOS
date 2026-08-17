import SwiftUI

struct ThumbnailImageView: View {
    let url: String?
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 0

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        PlaceholderImageView(height: height)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                            .clipped()
                    case .failure:
                        PlaceholderImageView(height: height)
                    @unknown default:
                        PlaceholderImageView(height: height)
                    }
                }
            } else {
                PlaceholderImageView(height: height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct PlaceholderImageView: View {
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.primaryNavy.opacity(0.15), Color.accentBlue.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.primaryNavy.opacity(0.4))
                    Text("画像なし")
                        .font(.caption)
                        .foregroundColor(.textGray)
                }
            )
    }
}
