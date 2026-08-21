import SwiftUI

struct MyLandDetailView: View {
    let land: Land
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailImageView(url: land.thumbnailUrl, height: 250)
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(land.name)
                            .font(.title2).fontWeight(.bold).foregroundColor(.textDark)
                        Spacer()
                        StatusBadge(status: land.status, type: .land)
                    }
                    Label(land.address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline).foregroundColor(.textGray)
                    Divider()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        PropertyDetailItem(label: "面積", value: "\(String(format: "%.1f", land.area))㎡", icon: "square.dashed")
                        if let zoning = land.zoning {
                            PropertyDetailItem(label: "用途地域", value: zoning, icon: "map")
                        }
                        if let price = land.purchasePrice {
                            PropertyDetailItem(label: "購入価格", value: formatCurrency(price), icon: "yensign.circle")
                        }
                        if let value = land.currentValue {
                            PropertyDetailItem(label: "現在評価額", value: formatCurrency(value), icon: "chart.line.uptrend.xyaxis")
                        }
                    }
                    Divider()
                    VStack(spacing: 12) {
                        NavigationLink {
                            LandManageView(land: land)
                        } label: {
                            ManagementLinkRow(icon: "wrench.and.screwdriver.fill", title: "土地管理", subtitle: "タスク・契約の管理", color: .primaryNavy)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LandChatListView(land: land)
                        } label: {
                            ManagementLinkRow(icon: "message.fill", title: "チャット", subtitle: "関係者とのやり取り", color: .accentBlue)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ValuationView()
                        } label: {
                            ManagementLinkRow(icon: "chart.bar.fill", title: "資産評価", subtitle: "土地の評価額シミュレーション", color: .warningOrange)
                        }
                        .buttonStyle(.plain)
                    }
                    if let notes = land.notes, !notes.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("備考").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                            Text(notes).font(.body).foregroundColor(.textDark)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.backgroundGray)
        .navigationTitle("土地詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) {
                    Image(systemName: "pencil").foregroundColor(.primaryNavy)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditLandView(land: land)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100_000_000 { return String(format: "%.1f億円", value / 100_000_000) }
        if value >= 10_000 { return String(format: "%.0f万円", value / 10_000) }
        return "¥\(Int(value))"
    }
}

struct EditLandView: View {
    let land: Land
    @StateObject private var vm = LandViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address: String
    @State private var status: String
    @State private var isPublic: Bool
    @State private var currentValue: String
    @State private var notes: String

    init(land: Land) {
        self.land = land
        _name = State(initialValue: land.name)
        _address = State(initialValue: land.address)
        _status = State(initialValue: land.status)
        _isPublic = State(initialValue: land.isPublic ?? false)
        _currentValue = State(initialValue: land.currentValue.map { String($0) } ?? "")
        _notes = State(initialValue: land.notes ?? "")
    }

    let statuses = [("owned", "所有中"), ("for_sale", "売却中"), ("rented", "賃貸中"), ("vacant", "空き")]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("土地名", text: $name)
                    TextField("住所", text: $address)
                }
                Section("ステータス") {
                    Picker("状態", selection: $status) {
                        ForEach(statuses, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Toggle("公開する", isOn: $isPublic)
                }
                Section("評価額") {
                    TextField("現在評価額 (円)", text: $currentValue).keyboardType(.decimalPad)
                }
                Section("備考") {
                    TextEditor(text: $notes).frame(height: 100)
                }
            }
            .navigationTitle("土地を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            let success = await vm.updateLand(
                                land.id, name: name, address: address,
                                status: status, isPublic: isPublic,
                                currentValue: Double(currentValue),
                                notes: notes.isEmpty ? nil : notes
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
    }
}

struct LandManageView: View {
    let land: Land
    @StateObject private var taskVM = TaskViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(land.name).font(.headline).foregroundColor(.textDark)
                        Text(land.address).font(.caption).foregroundColor(.textGray)
                    }
                    Spacer()
                    StatusBadge(status: land.status, type: .land)
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("タスク").font(.headline).foregroundColor(.textDark)
                        Spacer()
                        NavigationLink("詳細") { TaskManageView() }.font(.caption).foregroundColor(.accentBlue)
                    }
                    if taskVM.tasks.isEmpty {
                        Text("タスクが登録されていません").font(.caption).foregroundColor(.textGray)
                    } else {
                        ForEach(taskVM.pendingTasks.prefix(3)) { task in
                            TaskRowView(task: task)
                        }
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("土地管理")
        .navigationBarTitleDisplayMode(.inline)
        .task { await taskVM.fetchTasks(landId: land.id) }
    }
}

struct LandChatListView: View {
    let land: Land
    @StateObject private var vm = ChatViewModel()
    @State private var showCreateChat = false

    var body: some View {
        Group {
            if vm.chatRooms.filter({ $0.landId == land.id }).isEmpty {
                EmptyStateView(
                    title: "チャットルームなし",
                    message: "チャットルームを作成してください",
                    systemImage: "message",
                    actionTitle: "作成",
                    action: { showCreateChat = true }
                )
            } else {
                List(vm.chatRooms.filter { $0.landId == land.id }) { room in
                    NavigationLink { ChatRoomView(chatRoom: room) } label: { ChatRoomRow(room: room) }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("\(land.name) チャット")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateChat = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchChatRooms() }
        .sheet(isPresented: $showCreateChat) {
            CreateChatRoomView(vm: vm, landId: land.id)
        }
    }
}
