import Foundation

struct AppTask: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let propertyId: String?
    let landId: String?
    let assigneeId: String?
    let assigneeName: String?
    let priority: String
    let status: String
    let dueDate: String?
    let completedAt: String?
    let category: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case propertyId
        case landId
        case assigneeId
        case assigneeName
        case priority
        case status
        case dueDate
        case completedAt
        case category
        case notes
        case createdAt
        case updatedAt
    }
}

struct CreateTaskRequest: Codable {
    let title: String
    let description: String?
    let propertyId: String?
    let landId: String?
    let assigneeId: String?
    let priority: String
    let dueDate: String?
    let category: String?
    let notes: String?
}

struct UpdateTaskRequest: Codable {
    let title: String?
    let description: String?
    let assigneeId: String?
    let priority: String?
    let status: String?
    let dueDate: String?
    let notes: String?
}

struct AISuggestTasksRequest: Codable {
    let propertyId: String?
    let landId: String?
    let context: String?
}

struct AISuggestTasksResponse: Codable {
    let suggestions: [TaskSuggestion]
}

struct TaskSuggestion: Codable {
    let title: String
    let description: String
    let priority: String
    let category: String
    let estimatedDays: Int?
}
