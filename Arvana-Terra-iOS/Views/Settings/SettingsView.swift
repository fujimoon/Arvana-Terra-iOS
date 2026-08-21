import SwiftUI

// MARK: - 設定画面
struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var regionManager = RegionModeManager.shared

    // 表示エリア設定
    @State private var selectedMode: RegionModeManager.DisplayMode = RegionModeManager.shared.displayMode
    @State private var displayPrefectures: [String] = RegionModeManager.shared.displayPrefectures

    // プロフィール編集
    @State private var profileName: String = ""
    @State private var profilePhone: String = ""
    @State private var profileAddress: String = ""
    @State private var profilePrefecture: [String] = []
    @State private var profilePrefectures: [String] = []

    // 状態管理
    @State private var isSavingArea = false
    @State private var isSavingProfile = false
    @State private var areaAlertMessage: String?
    @State private var profileAlertMessage: String?
    @State private var showAreaAlert = false
    @State private var showProfileAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 表示エリア設定セクション
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("表示モードを選択してください")
                            .font(.caption)
                            .foregroundColor(Color.textGray)

                        Picker("表示モード", selection: $selectedMode) {
                            ForEach(RegionModeManager.DisplayMode.allCases, id: \.self) { mode in
                                Label(mode.label, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if selectedMode == .regional {
                            Divider()
                            PrefectureSelectorView(
                                selected: $displayPrefectures,
                                label: "表示する都道府県（複数選択可）",
                                singleSelection: false
                            )
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("表示エリア設定")
                } footer: {
                    Text("地域モードでは選択した都道府県の物件・土地のみを一覧表示します。")
                        .font(.caption2)
                }

                Section {
                    Button(action: saveAreaSettings) {
                        HStack {
                            Spacer()
                            if isSavingArea {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("表示エリアを保存する")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .disabled(isSavingArea)
                    .foregroundColor(.white)
                    .listRowBackground(Color.primaryNavy)
                }

                // MARK: プロフィール設定セクション
                Section {
                    TextField("お名前", text: $profileName)
                    TextField("電話番号", text: $profilePhone)
                        .keyboardType(.phonePad)
                    TextField("住所", text: $profileAddress)
                } header: {
                    Text("プロフィール編集")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        PrefectureSelectorView(
                            selected: $profilePrefecture,
                            label: "都道府県（主要・1つ選択）",
                            singleSelection: true
                        )
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        PrefectureSelectorView(
                            selected: $profilePrefectures,
                            label: "活動エリア（複数選択可）",
                            singleSelection: false
                        )
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            if isSavingProfile {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("プロフィールを保存する")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .disabled(isSavingProfile)
                    .foregroundColor(.white)
                    .listRowBackground(Color.secondaryBlue)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .alert("表示エリア設定", isPresented: $showAreaAlert) {
                Button("OK") {}
            } message: {
                Text(areaAlertMessage ?? "")
            }
            .alert("プロフィール", isPresented: $showProfileAlert) {
                Button("OK") {}
            } message: {
                Text(profileAlertMessage ?? "")
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    // MARK: - 現在の設定をフォームに反映
    private func loadCurrentValues() {
        selectedMode = regionManager.displayMode
        displayPrefectures = regionManager.displayPrefectures

        if let user = authVM.currentUser {
            profileName = user.name
            profilePhone = user.phone ?? ""
        }
    }

    // MARK: - 表示エリア保存
    private func saveAreaSettings() {
        // ローカルのRegionModeManagerに即時反映
        regionManager.displayMode = selectedMode
        regionManager.displayPrefectures = displayPrefectures

        isSavingArea = true
        Task {
            do {
                _ = try await APIService.shared.updateUserPreference(
                    displayMode: selectedMode.rawValue,
                    displayPrefectures: displayPrefectures,
                    preferredRegions: nil
                )
                await MainActor.run {
                    areaAlertMessage = "表示エリアを保存しました"
                    showAreaAlert = true
                    isSavingArea = false
                }
            } catch {
                await MainActor.run {
                    areaAlertMessage = error.localizedDescription
                    showAreaAlert = true
                    isSavingArea = false
                }
            }
        }
    }

    // MARK: - プロフィール保存
    private func saveProfile() {
        isSavingProfile = true
        Task {
            do {
                let updatedUser = try await APIService.shared.updateUserProfile(
                    name: profileName.isEmpty ? nil : profileName,
                    phone: profilePhone.isEmpty ? nil : profilePhone,
                    address: profileAddress.isEmpty ? nil : profileAddress,
                    bio: nil,
                    prefecture: profilePrefecture.first,
                    prefectures: profilePrefectures.isEmpty ? nil : profilePrefectures
                )
                await MainActor.run {
                    // AuthViewModelのユーザー情報を更新
                    authVM.currentUser = updatedUser
                    if let data = try? JSONEncoder().encode(updatedUser) {
                        UserDefaults.standard.set(data, forKey: "currentUser")
                    }
                    profileAlertMessage = "プロフィールを保存しました"
                    showProfileAlert = true
                    isSavingProfile = false
                }
            } catch {
                await MainActor.run {
                    profileAlertMessage = error.localizedDescription
                    showProfileAlert = true
                    isSavingProfile = false
                }
            }
        }
    }
}
