import Foundation
import SwiftUI

@MainActor
class EmployeeViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    @Published var selectedEmployee: Employee?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchEmployees() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            employees = try await apiService.getEmployees()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchEmployeeById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedEmployee = try await apiService.getEmployeeById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var activeEmployees: [Employee] {
        employees.filter { $0.status == "active" }
    }

    func departmentLabel(_ dept: String?) -> String {
        guard let dept = dept else { return "未設定" }
        return dept
    }

    func employmentTypeLabel(_ type: String?) -> String {
        switch type {
        case "full_time": return "正社員"
        case "part_time": return "パートタイム"
        case "contract": return "契約社員"
        case "temporary": return "派遣社員"
        default: return type ?? "未設定"
        }
    }
}
