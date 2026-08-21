import SwiftUI

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func fetchNotifications() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notifications = try await apiService.getNotifications()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markRead(id: String) async {
        do {
            try await apiService.markNotificationRead(id: id)
            if let idx = notifications.firstIndex(where: { $0.id == id }) {
                // Rebuild with isRead = true (Codable struct is immutable)
                let n = notifications[idx]
                notifications[idx] = AppNotification(
                    id: n.id, userId: n.userId, title: n.title, body: n.body,
                    notificationType: n.notificationType, relatedId: n.relatedId,
                    relatedType: n.relatedType, isRead: true, createdAt: n.createdAt
                )
            }
        } catch {}
    }

    func markAllRead() async {
        do {
            try await apiService.markAllNotificationsRead()
            notifications = notifications.map { n in
                AppNotification(
                    id: n.id, userId: n.userId, title: n.title, body: n.body,
                    notificationType: n.notificationType, relatedId: n.relatedId,
                    relatedType: n.relatedType, isRead: true, createdAt: n.createdAt
                )
            }
        } catch {}
    }

    func typeIcon(_ type: String) -> String {
        switch type {
        case "payment_due", "payment_overdue": return "yensign.circle.fill"
        case "camera_alert": return "camera.fill"
        case "contract_expiry": return "doc.text.fill"
        case "task_assigned": return "checkmark.circle.fill"
        case "chat_message": return "bubble.left.fill"
        default: return "bell.fill"
        }
    }

    func typeColor(_ type: String) -> Color {
        switch type {
        case "payment_due": return .warningOrange
        case "payment_overdue": return .errorRed
        case "camera_alert": return .errorRed
        case "contract_expiry": return .warningOrange
        case "task_assigned": return .accentBlue
        case "chat_message": return .successGreen
        default: return .primaryNavy
        }
    }
}

struct NotificationListView: View {
    @StateObject private var vm = NotificationViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.notifications.isEmpty {
                    LoadingView()
                } else if vm.notifications.isEmpty {
                    EmptyStateView(
                        title: "通知なし",
                        message: "新しい通知はありません",
                        systemImage: "bell.slash",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    List {
                        ForEach(vm.notifications) { notification in
                            NotificationRow(notification: notification, vm: vm)
                                .listRowBackground(notification.isRead ? Color.clear : Color.accentBlue.opacity(0.05))
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.unreadCount > 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("すべて既読") {
                            Task { await vm.markAllRead() }
                        }
                        .font(.caption)
                        .foregroundColor(.primaryNavy)
                    }
                }
            }
            .task { await vm.fetchNotifications() }
            .refreshable { await vm.fetchNotifications() }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    @ObservedObject var vm: NotificationViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(vm.typeColor(notification.notificationType).opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: vm.typeIcon(notification.notificationType))
                        .font(.caption)
                        .foregroundColor(vm.typeColor(notification.notificationType))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.textDark)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(Color.accentBlue).frame(width: 8, height: 8)
                    }
                }
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.textGray)
                    .lineLimit(2)
                Text(formatDate(notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.textGray.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !notification.isRead {
                Task { await vm.markRead(id: notification.id) }
            }
        }
    }

    func formatDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let date = f.date(from: iso) else { return iso }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
