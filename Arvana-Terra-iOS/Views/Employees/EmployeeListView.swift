import SwiftUI

struct EmployeeListView: View {
    @StateObject private var vm = EmployeeViewModel()
    @State private var searchText = ""

    var filteredEmployees: [Employee] {
        if searchText.isEmpty { return vm.employees }
        return vm.employees.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.department?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.employees.isEmpty {
                LoadingView()
            } else if filteredEmployees.isEmpty {
                EmptyStateView(title: "従業員なし", message: "従業員が登録されていません", systemImage: "person.3")
            } else {
                List {
                    ForEach(filteredEmployees) { employee in
                        NavigationLink {
                            EmployeeDetailView(employee: employee)
                        } label: {
                            EmployeeRow(employee: employee, vm: vm)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("従業員")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "名前・部署で検索")
        .task { await vm.fetchEmployees() }
    }
}

struct EmployeeRow: View {
    let employee: Employee
    @ObservedObject var vm: EmployeeViewModel

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentBlue.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(employee.name.prefix(1)))
                        .font(.headline).fontWeight(.bold).foregroundColor(.primaryNavy)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                if let dept = employee.department, let pos = employee.position {
                    Text("\(dept) · \(pos)").font(.caption).foregroundColor(.textGray)
                } else if let dept = employee.department {
                    Text(dept).font(.caption).foregroundColor(.textGray)
                }
                Text(vm.employmentTypeLabel(employee.employmentType))
                    .font(.caption).foregroundColor(.accentBlue)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(employee.status == "active" ? Color.successGreen : Color.textGray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
