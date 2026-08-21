import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showLogoutAlert = false
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @AppStorage("apiBaseURL") private var apiBaseURL = AppConfig.apiBaseURL

    var body: some View {
        List {
                // Profile section
                Section {
                    NavigationLink {
                        UserProfileView()
                            .environmentObject(authVM)
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.accentBlue.opacity(0.15))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(String(authVM.currentUser?.name.prefix(1) ?? "U"))
                                        .font(.title).fontWeight(.bold).foregroundColor(.primaryNavy)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authVM.currentUser?.name ?? "ユーザー")
                                    .font(.headline).foregroundColor(.textDark)
                                Text(authVM.currentUser?.email ?? "")
                                    .font(.subheadline).foregroundColor(.textGray)
                                Text(roleLabel(authVM.currentUser?.role ?? ""))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.primaryNavy)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Navigation items
                Section("管理") {
                    SettingsNavRow(icon: "building.2.fill", title: "マイ物件", color: .primaryNavy) {
                        AnyView(MyPropertyListView())
                    }
                    SettingsNavRow(icon: "map.fill", title: "マイ土地", color: .secondaryBlue) {
                        AnyView(MyLandListView())
                    }
                    SettingsNavRow(icon: "person.3.fill", title: "従業員管理", color: .accentBlue) {
                        AnyView(EmployeeListView())
                    }
                    SettingsNavRow(icon: "person.text.rectangle.fill", title: "業者管理", color: .warningOrange) {
                        AnyView(VendorListView())
                    }
                    SettingsNavRow(icon: "doc.text.fill", title: "契約管理", color: .successGreen) {
                        AnyView(ContractListView())
                    }
                    SettingsNavRow(icon: "yensign.circle.fill", title: "入金管理", color: .primaryNavy) {
                        AnyView(PaymentPropertySelectorView())
                    }
                    SettingsNavRow(icon: "sensor.tag.radiowaves.forward.fill", title: "スマートデバイス", color: .accentBlue) {
                        AnyView(SmartDevicePropertySelectorView())
                    }
                    SettingsNavRow(icon: "bell.fill", title: "通知センター", color: .warningOrange) {
                        AnyView(NotificationListView())
                    }
                    SettingsNavRow(icon: "chart.bar.fill", title: "分析・可視化", color: .errorRed) {
                        AnyView(VisualizationView())
                    }
                    SettingsNavRow(icon: "briefcase.fill", title: "ビジネス機会", color: .textGray) {
                        AnyView(OpportunitiesView())
                    }
                }

                // App settings
                Section("アプリ設定") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label {
                            Text("プッシュ通知")
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.warningOrange)
                        }
                    }

                    HStack {
                        Label {
                            Text("API URL")
                        } icon: {
                            Image(systemName: "network")
                                .foregroundColor(.accentBlue)
                        }
                        Spacer()
                        Text(AppConfig.apiBaseURL)
                            .font(.caption)
                            .foregroundColor(.textGray)
                            .lineLimit(1)
                    }
                }

                // App info
                Section("アプリ情報") {
                    HStack {
                        Label("バージョン", systemImage: "info.circle.fill")
                        Spacer()
                        Text(AppConfig.appVersion).foregroundColor(.textGray)
                    }
                    HStack {
                        Label("プラットフォーム", systemImage: "iphone")
                        Spacer()
                        Text("iOS").foregroundColor(.textGray)
                    }
                    Link(destination: URL(string: "https://arvana-terra.example.com/privacy")!) {
                        Label("プライバシーポリシー", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://arvana-terra.example.com/terms")!) {
                        Label("利用規約", systemImage: "doc.text.fill")
                    }
                }

                // Logout
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.backward.square.fill")
                                .foregroundColor(.errorRed)
                            Text("ログアウト")
                                .foregroundColor(.errorRed)
                        }
                    }
                }
            }
        .navigationTitle("設定")
        .alert("ログアウト", isPresented: $showLogoutAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("ログアウト", role: .destructive) {
                Task { await authVM.logout() }
            }
        } message: {
            Text("ログアウトしますか？")
        }
    }

    func roleLabel(_ role: String) -> String {
        switch role {
        case "owner": return "オーナー"
        case "manager": return "管理者"
        case "tenant": return "テナント"
        case "vendor": return "業者"
        case "admin": return "管理者"
        default: return role
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let content: () -> Content

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: icon).font(.caption).foregroundColor(color))
            Text(title)
            Spacer()
        }
    }
}

struct UserProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.15))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text(String(authVM.currentUser?.name.prefix(1) ?? "U"))
                                .font(.largeTitle).fontWeight(.bold).foregroundColor(.primaryNavy)
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(authVM.currentUser?.name ?? "ユーザー")
                            .font(.title3).fontWeight(.semibold)
                        Text(authVM.currentUser?.email ?? "")
                            .font(.subheadline).foregroundColor(.textGray)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("アカウント情報") {
                ProfileRow(label: "役割", value: roleLabelFull(authVM.currentUser?.role ?? ""))
                ProfileRow(label: "ユーザーID", value: authVM.currentUser?.id ?? "-")
                if let createdAt = authVM.currentUser?.createdAt {
                    ProfileRow(label: "登録日", value: formatDate(createdAt))
                }
            }
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
    }

    func roleLabelFull(_ role: String) -> String {
        switch role {
        case "owner": return "オーナー"
        case "manager": return "管理者"
        case "tenant": return "テナント"
        case "vendor": return "業者"
        case "admin": return "システム管理者"
        case "landlord": return "大家"
        default: return role
        }
    }

    func formatDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        guard let d = f.date(from: iso) else { return iso }
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateStyle = .medium
        return df.string(from: d)
    }
}

struct ProfileRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.textGray)
            Spacer()
            Text(value).foregroundColor(.textDark).multilineTextAlignment(.trailing)
        }
    }
}

struct SettingsNavRow: View {
    let icon: String
    let title: String
    let color: Color
    let destination: () -> AnyView

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: icon).font(.caption).foregroundColor(color))
                Text(title)
            }
        }
    }
}
