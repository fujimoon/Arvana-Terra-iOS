import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    let currentUserId: String

    private var isFromMe: Bool {
        message.senderId == currentUserId
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromMe {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.primaryNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    Text(formatTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.textGray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.textGray)
                        .padding(.leading, 4)

                    HStack(alignment: .bottom, spacing: 6) {
                        Circle()
                            .fill(Color.accentBlue.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(message.senderName.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentBlue)
                            )

                        Text(message.content)
                            .font(.body)
                            .foregroundColor(.textDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)

                        Text(formatTime(message.createdAt))
                            .font(.caption2)
                            .foregroundColor(.textGray)
                    }
                }
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 12)
    }

    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        displayFormatter.locale = Locale(identifier: "ja_JP")
        return displayFormatter.string(from: date)
    }
}
