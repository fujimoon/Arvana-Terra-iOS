import Foundation

class ScheduleService {
    static let shared = ScheduleService()
    private init() {}

    private func authRequest(_ url: URL, method: String = "GET", body: [String: Any]? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    func getSchedules(year: Int, month: Int) async throws -> [Schedule] {
        var comps = URLComponents(string: "\(AppConfig.baseURL)/schedules")!
        comps.queryItems = [
            URLQueryItem(name: "year", value: "\(year)"),
            URLQueryItem(name: "month", value: "\(month)"),
        ]
        let (data, _) = try await URLSession.shared.data(for: authRequest(comps.url!))
        return (try JSONDecoder().decode([String: [Schedule]].self, from: data))["schedules"] ?? []
    }

    func getUpcoming(limit: Int = 10) async throws -> [Schedule] {
        var comps = URLComponents(string: "\(AppConfig.baseURL)/schedules/upcoming")!
        comps.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        let (data, _) = try await URLSession.shared.data(for: authRequest(comps.url!))
        return (try JSONDecoder().decode([String: [Schedule]].self, from: data))["schedules"] ?? []
    }

    func createSchedule(data: [String: Any]) async throws -> Schedule {
        let url = URL(string: "\(AppConfig.baseURL)/schedules")!
        let (resData, _) = try await URLSession.shared.data(for: authRequest(url, method: "POST", body: data))
        return (try JSONDecoder().decode([String: Schedule].self, from: resData))["schedule"]!
    }

    func updateSchedule(id: String, data: [String: Any]) async throws -> Schedule {
        let url = URL(string: "\(AppConfig.baseURL)/schedules/\(id)")!
        let (resData, _) = try await URLSession.shared.data(for: authRequest(url, method: "PUT", body: data))
        return (try JSONDecoder().decode([String: Schedule].self, from: resData))["schedule"]!
    }

    func completeSchedule(id: String) async throws {
        let url = URL(string: "\(AppConfig.baseURL)/schedules/\(id)/complete")!
        _ = try await URLSession.shared.data(for: authRequest(url, method: "PATCH"))
    }

    func deleteSchedule(id: String) async throws {
        let url = URL(string: "\(AppConfig.baseURL)/schedules/\(id)")!
        _ = try await URLSession.shared.data(for: authRequest(url, method: "DELETE"))
    }
}
