import SwiftUI

struct MyPropertyListView: View {
    @StateObject private var vm = PropertyViewModel()
    @State private var showAddSheet = false
    @State private var searchText = ""

    var filteredProperties: [Property] {
        if searchText.isEmpty { return vm.myProperties }
        return vm.myProperties.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.myProperties.isEmpty {
                LoadingView()
            } else if let error = vm.errorMessage {
                ErrorView(message: error) {
                    Task { await vm.fetchMyProperties() }
                }
            } else if filteredProperties.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    title: "物件がありません",
                    message: "最初の物件を登録してみましょう",
                    systemImage: "building.2",
                    actionTitle: "物件を追加",
                    action: { showAddSheet = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredProperties) { property in
                            NavigationLink {
                                MyPropertyDetailView(property: property)
                            } label: {
                                PropertyCard(property: property)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.backgroundGray)
            }
        }
        .navigationTitle("マイ物件")
        .searchable(text: $searchText, prompt: "物件名・住所で検索")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchMyProperties() }
        .sheet(isPresented: $showAddSheet) {
            AddPropertyView(vm: vm)
        }
    }
}

struct AddPropertyView: View {
    @ObservedObject var vm: PropertyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var buildingType = "apartment"
    @State private var floors = "1"
    @State private var totalRooms = "1"
    @State private var area = ""
    @State private var status = "owned"
    @State private var isPublic = false
    @State private var purchasePrice = ""
    @State private var notes = ""

    let buildingTypes = [("apartment", "マンション"), ("house", "一戸建て"), ("office", "オフィス"), ("commercial", "商業施設"), ("warehouse", "倉庫")]
    let statuses = [("owned", "所有中"), ("for_sale", "売却中"), ("rented", "賃貸中"), ("vacant", "空き"), ("under_construction", "建設中")]

    var isValid: Bool {
        !name.isEmpty && !address.isEmpty && !area.isEmpty && Double(area) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("物件名 *", text: $name)
                    TextField("住所 *", text: $address)
                    Picker("建物種別", selection: $buildingType) {
                        ForEach(buildingTypes, id: \.0) { Text($0.1).tag($0.0) }
                    }
                }
                Section("規模") {
                    TextField("延床面積 (㎡) *", text: $area).keyboardType(.decimalPad)
                    TextField("階数", text: $floors).keyboardType(.numberPad)
                    TextField("総部屋数", text: $totalRooms).keyboardType(.numberPad)
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
            .navigationTitle("物件を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let success = await vm.createProperty(
                                name: name, address: address, buildingType: buildingType,
                                floors: Int(floors) ?? 1, totalRooms: Int(totalRooms) ?? 1,
                                area: Double(area) ?? 0, status: status, isPublic: isPublic,
                                purchasePrice: Double(purchasePrice), notes: notes.isEmpty ? nil : notes
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
