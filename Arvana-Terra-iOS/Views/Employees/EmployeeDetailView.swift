import SwiftUI

// MARK: - 従業員詳細画面
struct EmployeeDetailView: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    @State private var showEditSheet = false

    var contractLabel: String {
        switch employee.contractType {
        case "full_time": return "正社員"
        case "part_time": return "パート"
        case "contract": return "契約社員"
        case "temp": return "派遣"
        default: return "不明"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: ヘッダー（アバター・名前・ステータス）
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(employee.isActive ? Color.primaryNavy.opacity(0.15) : Color.borderGray.opacity(0.4))
                            .frame(width: 72, height: 72)
                        Text(String(employee.name.prefix(1)))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(employee.isActive ? Color.primaryNavy : Color.textGray)
                    }
                    Text(employee.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textDark)

                    HStack(spacing: 8) {
                        if let dept = employee.department {
                            Text(dept)
                                .font(.subheadline)
                                .foregroundColor(Color.textGray)
                        }
                        if let role = employee.role {
                            Text(role)
                                .font(.subheadline)
                                .foregroundColor(Color.textGray)
                        }
                    }

                    HStack(spacing: 8) {
                        if employee.contractType != nil {
                            Text(contractLabel)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.primaryNavy.opacity(0.12))
                                .foregroundColor(Color.primaryNavy)
                                .cornerRadius(12)
                        }
                        Text(employee.isActive ? "在職中" : "退職済み")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(employee.isActive ? Color.successGreen.opacity(0.12) : Color.errorRed.opacity(0.12))
                            .foregroundColor(employee.isActive ? Color.successGreen : Color.errorRed)
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)

                // MARK: 連絡先情報カード
                InfoCardView(title: "連絡先") {
                    if let email = employee.email {
                        InfoRowView(icon: "envelope", label: "メールアドレス", value: email)
                    }
                    if let phone = employee.phone {
                        InfoRowView(icon: "phone", label: "電話番号", value: phone)
                    }
                    if let address = employee.address {
                        InfoRowView(icon: "location", label: "住所", value: address)
                    }
                    if employee.email == nil && employee.phone == nil && employee.address == nil {
                        Text("連絡先情報が登録されていません")
                            .font(.subheadline)
                            .foregroundColor(Color.textGray)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)

                // MARK: 雇用情報カード
                InfoCardView(title: "雇用情報") {
                    if let hireDate = employee.hireDate {
                        InfoRowView(icon: "calendar", label: "入社日", value: hireDate)
                    }
                    if employee.contractType != nil {
                        InfoRowView(icon: "briefcase", label: "雇用形態", value: contractLabel)
                    }
                }
                .padding(.horizontal)

                // MARK: マイナンバーカード
                MyNumberView(mynumber: employee.mynumber, verified: employee.mynumberVerified)
                    .padding(.horizontal)

                // MARK: 備考カード
                if let notes = employee.notes, !notes.isEmpty {
                    InfoCardView(title: "備考") {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(Color.textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }

                // MARK: チャットリンク
                InfoCardView(title: "コミュニケーション") {
                    NavigationLink(destination: ChatListView(type: "employee", targetId: employee.id, targetName: employee.name)) {
                        Label("チャット", systemImage: "bubble.left.and.bubble.right")
                            .foregroundColor(Color.primaryNavy)
                    }
                }
                .padding(.horizontal)

                // MARK: メタ情報
                InfoCardView(title: "登録情報") {
                    InfoRowView(icon: "clock", label: "登録日時", value: formatDate(employee.createdAt))
                    InfoRowView(icon: "pencil", label: "更新日時", value: formatDate(employee.updatedAt))
                }
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
        }
        .navigationTitle("従業員詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EmployeeEditView(employee: employee, viewModel: viewModel)
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            display.locale = Locale(identifier: "ja_JP")
            return display.string(from: date)
        }
        return dateStr
    }
}

// MARK: - マイナンバー表示コンポーネント
struct MyNumberView: View {
    let mynumber: String?
    let verified: Bool
    @State private var isRevealed = false

    var formatted: String? {
        guard let m = mynumber else { return nil }
        let digits = m.filter(\.isNumber)
        guard digits.count == 12 else { return m }
        let a = digits.prefix(4)
        let b = digits.dropFirst(4).prefix(4)
        let c = digits.dropFirst(8)
        return "\(a)-\(b)-\(c)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("マイナンバー")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textDark)
                Spacer()
                if verified {
                    Label("確認済み", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.successGreen)
                } else {
                    Label("未確認", systemImage: "circle")
                        .font(.caption)
                        .foregroundColor(Color.textGray)
                }
            }

            if let formatted {
                HStack {
                    Text(isRevealed ? formatted : "****-****-****")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(Color.textDark)
                    Spacer()
                    Button(isRevealed ? "隠す" : "表示") {
                        isRevealed.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(Color.primaryNavy)
                }
            } else {
                Text("未登録")
                    .foregroundColor(Color.textGray)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 情報カードコンポーネント
struct InfoCardView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.textGray)
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 情報行コンポーネント
struct InfoRowView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color.primaryNavy)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.textGray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(Color.textDark)
            }
            Spacer()
        }
    }
}

// MARK: - 従業員編集画面
struct EmployeeEditView: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var role: String
    @State private var department: String
    @State private var hireDate: String
    @State private var contractType: String
    @State private var notes: String
    @State private var isActive: Bool

    let contractTypes = [
        ("full_time", "正社員"),
        ("part_time", "パート"),
        ("contract", "契約社員"),
        ("temp", "派遣")
    ]

    init(employee: Employee, viewModel: EmployeeViewModel) {
        self.employee = employee
        self.viewModel = viewModel
        _name = State(initialValue: employee.name)
        _email = State(initialValue: employee.email ?? "")
        _phone = State(initialValue: employee.phone ?? "")
        _address = State(initialValue: employee.address ?? "")
        _role = State(initialValue: employee.role ?? "")
        _department = State(initialValue: employee.department ?? "")
        _hireDate = State(initialValue: employee.hireDate ?? "")
        _contractType = State(initialValue: employee.contractType ?? "full_time")
        _notes = State(initialValue: employee.notes ?? "")
        _isActive = State(initialValue: employee.isActive)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("氏名（必須）", text: $name)
                    TextField("メールアドレス", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("電話番号", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("住所", text: $address)
                }

                Section("所属・役職") {
                    TextField("部署", text: $department)
                    TextField("役職", text: $role)
                }

                Section("雇用情報") {
                    Picker("雇用形態", selection: $contractType) {
                        ForEach(contractTypes, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    TextField("入社日（例: 2024-04-01）", text: $hireDate)
                    Toggle("在職中", isOn: $isActive)
                }

                Section("備考") {
                    TextField("メモ・備考", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(action: updateEmployee) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("変更を保存する")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || viewModel.isSaving)
                    .foregroundColor(.white)
                    .listRowBackground(name.isEmpty ? Color.borderGray : Color.primaryNavy)
                }
            }
            .navigationTitle("従業員を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
        }
    }

    private func updateEmployee() {
        var data: [String: Any] = ["name": name, "isActive": isActive]
        if !email.isEmpty { data["email"] = email }
        if !phone.isEmpty { data["phone"] = phone }
        if !address.isEmpty { data["address"] = address }
        if !role.isEmpty { data["role"] = role }
        if !department.isEmpty { data["department"] = department }
        if !hireDate.isEmpty { data["hireDate"] = hireDate }
        data["contractType"] = contractType
        if !notes.isEmpty { data["notes"] = notes }

        Task {
            await viewModel.updateEmployee(id: employee.id, data: data)
            if !viewModel.showError {
                dismiss()
            }
        }
    }
}
