import SwiftUI

struct MyLandListView: View {
    @StateObject private var vm = LandViewModel()
    @State private var showAddSheet = false
    @State private var searchText = ""

    var filteredLands: [Land] {
        if searchText.isEmpty { return vm.myLands }
        return vm.myLands.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.myLands.isEmpty {
                LoadingView()
            } else if let error = vm.errorMessage {
                ErrorView(message: error) {
                    Task { await vm.fetchMyLands() }
                }
            } else if filteredLands.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    title: "土地がありません",
                    message: "最初の土地を登録してみましょう",
                    systemImage: "map",
                    actionTitle: "土地を追加",
                    action: { showAddSheet = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredLands) { land in
                            NavigationLink {
                                MyLandDetailView(land: land)
                            } label: {
                                LandCard(land: land)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.backgroundGray)
            }
        }
        .navigationTitle("マイ土地")
        .searchable(text: $searchText, prompt: "土地名・住所で検索")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchMyLands() }
        .sheet(isPresented: $showAddSheet) {
            AddLandView(vm: vm)
        }
    }
}

struct AddLandView: View {
    @ObservedObject var vm: LandViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var area = ""
    @State private var zoning = ""
    @State private var status = "owned"
    @State private var isPublic = false
    @State private var purchasePrice = ""
    @State private var notes = ""

    let statuses = [("owned", "所有中"), ("for_sale", "売却中"), ("rented", "賃貸中"), ("vacant", "空き")]

    var isValid: Bool { !name.isEmpty && !address.isEmpty && !area.isEmpty && Double(area) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("土地名 *", text: $name)
                    TextField("住所 *", text: $address)
                    TextField("用途地域", text: $zoning)
                }
                Section("面積") {
                    TextField("面積 (㎡) *", text: $area).keyboardType(.decimalPad)
                }
                Section("ステータス") {
                    Picker("状態", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Toggle("公開する", isOn: $isPublic)
                }
                Section("財務情報") {
                    TextField("購入価格 (円)", text: $purchasePrice).keyboardType(.decimalPad)
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 100)
                }
            }
            .navigationTitle("土地を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let success = await vm.createLand(
                                name: name, address: address, area: Double(area) ?? 0,
                                zoning: zoning.isEmpty ? nil : zoning,
                                status: status, isPublic: isPublic,
                                purchasePrice: Double(purchasePrice),
                                notes: notes.isEmpty ? nil : notes
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isValid || vm.isLoading)
                }
            }
        }
    }
}
