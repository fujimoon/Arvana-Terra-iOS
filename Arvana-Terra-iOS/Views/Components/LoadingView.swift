import SwiftUI

struct LoadingView: View {
    var message: String = "読み込み中..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryNavy))
                .scaleEffect(1.5)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.textGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundGray)
    }
}

struct InlineLoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryNavy))
            Spacer()
        }
        .padding()
    }
}

struct LoadingOverlay: View {
    var message: String = "処理中..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.primaryNavy.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
