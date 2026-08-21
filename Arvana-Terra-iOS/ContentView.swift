import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                MainTabView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            authVM.checkAuthStatus()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            PropertiesLandsTabView()
                .tabItem {
                    Label("物件・土地", systemImage: "building.2.fill")
                }

            SnsTimelineView()
                .tabItem {
                    Label("ネットワーク", systemImage: "person.3.fill")
                }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
        .accentColor(.primaryNavy)
    }
}

struct PropertiesLandsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("公開情報") {
                    NavigationLink("公開物件一覧") {
                        PublicPropertyListView()
                    }
                    NavigationLink("公開土地一覧") {
                        PublicLandListView()
                    }
                }
                Section("マイ物件・土地") {
                    NavigationLink("マイ物件") {
                        MyPropertyListView()
                    }
                    NavigationLink("マイ土地") {
                        MyLandListView()
                    }
                }
            }
            .navigationTitle("物件・土地")
        }
    }
}

#Preview {
    ContentView()
}
