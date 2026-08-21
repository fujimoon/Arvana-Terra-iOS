import SwiftUI

// MARK: - 従業員一覧画面
struct EmployeeListView: View {
    @StateObject private var viewModel = EmployeeViewModel()
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.employees.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.slash")
                            .font(.system(size: 52))
                            .foregroundColor(Color.borderGray)
                        Text("従業員が登録されていません")
                            .font(.headline)
                            .foregroundColor(Color.textGray)
                        Text("右上の「＋」ボタンから追加してください")
                            .font(.caption)
                            .foregroundColor(Color.textGray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.employees) { employee in
                        NavigationLink(destination: EmployeeDetailView(employee: employee, viewModel: viewModel)) {
                            EmployeeRowView(employee: employee)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("従業員管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
            .refreshable {
                await viewModel.loadEmployees()
            }
            .sheet(isPresented: $showCreateSheet) {
                EmployeeCreateView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadEmployees()
        }
    }
}

// MARK: - 従業員行ビュー
struct EmployeeRowView: View {
    let employee: Employee

    var contractLabel: String {
        switch employee.contractType {
        case "full_time": return "正社員"
        case "part_time": return "パート"
        case "contract": return "契約社員"
        case "temp": return "派遣"
        default: return "不明"
        }
    }

    var contractColor: Color {
        switch employee.contractType {
        case "full_time": return Color.primaryNavy
        case "part_time": return Color.secondaryBlue
        case "contract": return Color.accentBlue
        case "temp": return Color.warningOrange
        default: return Color.textGray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // アバター
            ZStack {
                Circle()
                    .fill(employee.isActive ? Color.primaryNavy.opacity(0.15) : Color.borderGray.opacity(0.4))
                    .frame(width: 48, height: 48)
                Text(String(employee.name.prefix(1)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(employee.isActive ? Color.primaryNavy : Color.textGray)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 6) {
                    Text(employee.name)
                        .font(.headline)
                        .foregroundColor(employee.isActive ? Color.textDark : Color.textGray)
                    if !employee.isActive {
                        Text("退職")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.errorRed.opacity(0.15))
                            .foregroundColor(Color.errorRed)
                            .cornerRadius(6)
                    }
                }

                HStack(spacing: 6) {
                    if let dept = employee.department {
                        Text(dept)
                            .font(.caption)
                            .foregroundColor(Color.textGray)
                    }
                    if let role = employee.role {
                        Text(role)
                            .font(.caption)
                            .foregroundColor(Color.textGray)
                    }
                }

                HStack(spacing: 6) {
                    if let contractType = employee.contractType {
                        Text(contractLabel)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(contractColor.opacity(0.15))
                            .foregroundColor(contractColor)
                            .cornerRadius(6)
                    }

                    // マイナンバー登録状態（番号そのものは表示しない）
                    HStack(spacing: 3) {
                        Image(systemName: employee.mynumberVerified ? "checkmark.shield.fill" : "shield.slash")
                            .font(.caption2)
                        Text(employee.mynumberVerified ? "マイナンバー確認済み" : "マイナンバー未確認")
                            .font(.caption2)
                    }
                    .foregroundColor(employee.mynumberVerified ? Color.successGreen : Color.textGray)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 従業員新規登録画面
struct EmployeeCreateView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var role = ""
    @State private var department = ""
    @State private var hireDate = ""
    @State private var contractType = "full_time"
    @State private var notes = ""

    let contractTypes = [
        ("full_time", "正社員"),
        ("part_time", "パート"),
        ("contract", "契約社員"),
        ("temp", "派遣")
    ]

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
                }

                Section("備考") {
                    TextField("メモ・備考", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(action: createEmployee) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("登録する")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || viewModel.isSaving)
                    .foregroundColor(.white)
                    .listRowBackground(name.isEmpty ? Color.borderGray : Color.primaryNavy)
                }
            }
            .navigationTitle("従業員を追加")
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

    private func createEmployee() {
        var data: [String: Any] = ["name": name]
        if !email.isEmpty { data["email"] = email }
        if !phone.isEmpty { data["phone"] = phone }
        if !address.isEmpty { data["address"] = address }
        if !role.isEmpty { data["role"] = role }
        if !department.isEmpty { data["department"] = department }
        if !hireDate.isEmpty { data["hireDate"] = hireDate }
        data["contractType"] = contractType
        if !notes.isEmpty { data["notes"] = notes }

        Task {
            await viewModel.createEmployee(data: data)
            if !viewModel.showError {
                dismiss()
            }
        }
    }
}

// MARK: - 従業員ビューモデル
@MainActor
class EmployeeViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage: String?

    func loadEmployees() async {
        isLoading = true
        do {
            employees = try await APIService.shared.getEmployees()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func createEmployee(data: [String: Any]) async {
        isSaving = true
        do {
            let newEmployee = try await APIService.shared.createEmployee(data: data)
            employees.insert(newEmployee, at: 0)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }

    func updateEmployee(id: String, data: [String: Any]) async {
        isSaving = true
        do {
            let updated = try await APIService.shared.updateEmployee(id: id, data: data)
            if let idx = employees.firstIndex(where: { $0.id == id }) {
                employees[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}
