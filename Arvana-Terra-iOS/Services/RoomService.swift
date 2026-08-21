import Foundation

class RoomService {
    static let shared = RoomService()
    private init() {}

    private var token: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }

    func getRoomsByProperty(propertyId: String) async throws -> [Room] {
        let url = URL(string: "\(AppConfig.baseURL)/properties/\(propertyId)/rooms")!
        var req = URLRequest(url: url)
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode([String: [Room]].self, from: data)
        return res["rooms"] ?? []
    }

    func getRoomById(id: String) async throws -> Room {
        let url = URL(string: "\(AppConfig.baseURL)/rooms/\(id)")!
        var req = URLRequest(url: url)
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode([String: Room].self, from: data)
        return res["room"]!
    }

    func createRoom(propertyId: String, data: [String: Any]) async throws -> Room {
        let url = URL(string: "\(AppConfig.baseURL)/properties/\(propertyId)/rooms")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: data)
        let (resData, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode([String: Room].self, from: resData)
        return res["room"]!
    }

    func updateRoom(id: String, data: [String: Any]) async throws -> Room {
        let url = URL(string: "\(AppConfig.baseURL)/rooms/\(id)")!
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: data)
        let (resData, _) = try await URLSession.shared.data(for: req)
        let res = try JSONDecoder().decode([String: Room].self, from: resData)
        return res["room"]!
    }
}

class TenantService {
    static let shared = TenantService()
    private init() {}

    private var token: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }

    private func authRequest(_ url: URL, method: String = "GET", body: [String: Any]? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    func getTenantsByRoom(roomId: String) async throws -> [Tenant] {
        let url = URL(string: "\(AppConfig.baseURL)/rooms/\(roomId)/tenants")!
        let (data, _) = try await URLSession.shared.data(for: authRequest(url))
        return (try JSONDecoder().decode([String: [Tenant]].self, from: data))["tenants"] ?? []
    }

    func getTenantById(id: String) async throws -> Tenant {
        let url = URL(string: "\(AppConfig.baseURL)/tenants/\(id)")!
        let (data, _) = try await URLSession.shared.data(for: authRequest(url))
        return (try JSONDecoder().decode([String: Tenant].self, from: data))["tenant"]!
    }

    func createTenant(roomId: String, data: [String: Any]) async throws -> Tenant {
        let url = URL(string: "\(AppConfig.baseURL)/rooms/\(roomId)/tenants")!
        let (resData, _) = try await URLSession.shared.data(for: authRequest(url, method: "POST", body: data))
        return (try JSONDecoder().decode([String: Tenant].self, from: resData))["tenant"]!
    }

    func updateTenant(id: String, data: [String: Any]) async throws -> Tenant {
        let url = URL(string: "\(AppConfig.baseURL)/tenants/\(id)")!
        let (resData, _) = try await URLSession.shared.data(for: authRequest(url, method: "PUT", body: data))
        return (try JSONDecoder().decode([String: Tenant].self, from: resData))["tenant"]!
    }

    func addFamilyMember(tenantId: String, data: [String: Any]) async throws -> FamilyMember {
        let url = URL(string: "\(AppConfig.baseURL)/tenants/\(tenantId)/family-members")!
        let (resData, _) = try await URLSession.shared.data(for: authRequest(url, method: "POST", body: data))
        return (try JSONDecoder().decode([String: FamilyMember].self, from: resData))["member"]!
    }

    func deleteFamilyMember(id: String) async throws {
        let url = URL(string: "\(AppConfig.baseURL)/family-members/\(id)")!
        _ = try await URLSession.shared.data(for: authRequest(url, method: "DELETE"))
    }

    func updatePaymentStatus(id: String, status: String) async throws {
        let url = URL(string: "\(AppConfig.baseURL)/payments/\(id)/status")!
        _ = try await URLSession.shared.data(for: authRequest(url, method: "PATCH", body: ["status": status]))
    }
}
