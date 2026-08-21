import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        if authVM.isLoggedIn {
            MainTabView()
                .environmentObject(authVM)
        } else {
            LoginView()
                .environmentObject(authVM)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            // Public listings tab
            NavigationStack {
                VStack(spacing: 0) {
                    // Sub-tabs for Properties and Lands
                    PublicListingsView()
                }
            }
            .tabItem {
                Label("物件・土地一覧", systemImage: "building.2")
            }

            // My Properties tab
            MyPropertyListView()
                .tabItem {
                    Label("マイ物件", systemImage: "house.fill")
                }

            // My Lands tab
            MyLandListView()
                .tabItem {
                    Label("マイ土地", systemImage: "map.fill")
                }

            // My Sale Requests tab
            MySaleRequestsView()
                .tabItem {
                    Label("売出し申請", systemImage: "arrow.up.right.square")
                }

            // Schedule tab
            ScheduleView()
                .tabItem {
                    Label("スケジュール", systemImage: "calendar")
                }

            // Employees tab
            EmployeeListView()
                .tabItem {
                    Label("従業員", systemImage: "person.3.fill")
                }

            // Profile tab
            ProfileView()
                .environmentObject(authVM)
                .tabItem {
                    Label("プロフィール", systemImage: "person.circle")
                }
        }
        .tint(Color.primaryNavy)
    }
}

// MARK: - Public Listings (Properties + Lands in one screen)
struct PublicListingsView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("種別", selection: $selectedSegment) {
                Text("物件").tag(0)
                Text("土地").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if selectedSegment == 0 {
                PublicPropertyListView()
            } else {
                PublicLandListView()
            }
        }
        .navigationTitle("売り出し中の一覧")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ModeSwitcherButton()
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var regionManager = RegionModeManager.shared

    var body: some View {
        NavigationStack {
            List {
                if let user = authVM.currentUser {
                    Section("アカウント情報") {
                        HStack {
                            Text("お名前")
                            Spacer()
                            Text(user.name).foregroundColor(Color.textGray)
                        }
                        HStack {
                            Text("メールアドレス")
                            Spacer()
                            Text(user.email).foregroundColor(Color.textGray).font(.caption)
                        }
                        if let phone = user.phone {
                            HStack {
                                Text("電話番号")
                                Spacer()
                                Text(phone).foregroundColor(Color.textGray)
                            }
                        }
                        HStack {
                            Text("種別")
                            Spacer()
                            Text(roleLabel(user.role)).foregroundColor(Color.textGray)
                        }
                    }
                }

                Section("表示エリア") {
                    HStack {
                        Label(regionManager.displayMode.label, systemImage: regionManager.displayMode.icon)
                            .foregroundColor(Color.primaryNavy)
                        Spacer()
                        if regionManager.isRegionalMode && !regionManager.displayPrefectures.isEmpty {
                            Text(regionManager.displayPrefectures.joined(separator: "・"))
                                .font(.caption)
                                .foregroundColor(Color.textGray)
                                .lineLimit(1)
                        }
                    }

                    NavigationLink(destination: SettingsView().environmentObject(authVM)) {
                        Label("設定を変更する", systemImage: "gearshape")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                    } label: {
                        Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("プロフィール")
        }
    }

    func roleLabel(_ role: String) -> String {
        switch role {
        case "homeowner": return "住宅オーナー"
        case "landlord": return "土地オーナー"
        case "admin": return "管理者"
        default: return role
        }
    }
}
