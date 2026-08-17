import Foundation
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var aiSuggestions: [TaskSuggestion] = []
    @Published var isLoading = false
    @Published var isSuggesting = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchTasks(propertyId: String? = nil, landId: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            tasks = try await apiService.getTasks(propertyId: propertyId, landId: landId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createTask(title: String, description: String?, propertyId: String?, landId: String?, assigneeId: String?, priority: String, dueDate: String?, category: String?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreateTaskRequest(
                title: title, description: description,
                propertyId: propertyId, landId: landId,
                assigneeId: assigneeId, priority: priority,
                dueDate: dueDate, category: category, notes: notes
            )
            let newTask = try await apiService.createTask(request)
            tasks.insert(newTask, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateTaskStatus(_ id: String, status: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = UpdateTaskRequest(
                title: nil, description: nil, assigneeId: nil,
                priority: nil, status: status, dueDate: nil, notes: nil
            )
            let updated = try await apiService.updateTask(id, request)
            if let idx = tasks.firstIndex(where: { $0.id == id }) {
                tasks[idx] = updated
            }
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func fetchAISuggestions(propertyId: String?, landId: String?, context: String?) async {
        isSuggesting = true
        errorMessage = nil
        defer { isSuggesting = false }
        do {
            let request = AISuggestTasksRequest(propertyId: propertyId, landId: landId, context: context)
            let response = try await apiService.aiSuggestTasks(request)
            aiSuggestions = response.suggestions
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var pendingTasks: [Task] { tasks.filter { $0.status == "pending" } }
    var inProgressTasks: [Task] { tasks.filter { $0.status == "in_progress" } }
    var completedTasks: [Task] { tasks.filter { $0.status == "completed" } }

    var overdueTasks: [Task] {
        let formatter = ISO8601DateFormatter()
        let now = Date()
        return tasks.filter { task in
            guard task.status != "completed",
                  let dueStr = task.dueDate,
                  let due = formatter.date(from: dueStr) else { return false }
            return due < now
        }
    }

    func priorityColor(_ priority: String) -> SwiftUI.Color {
        switch priority {
        case "high": return .errorRed
        case "medium": return .warningOrange
        case "low": return .successGreen
        default: return .textGray
        }
    }

    func priorityLabel(_ priority: String) -> String {
        switch priority {
        case "high": return "高"
        case "medium": return "中"
        case "low": return "低"
        default: return priority
        }
    }

    func statusLabel(_ status: String) -> String {
        switch status {
        case "pending": return "未着手"
        case "in_progress": return "進行中"
        case "completed": return "完了"
        case "cancelled": return "キャンセル"
        default: return status
        }
    }
}
