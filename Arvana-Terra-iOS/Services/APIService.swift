import Foundation

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .unauthorized: return "認証が必要です"
        case .serverError(let msg): return msg
        case .decodingError: return "データの解析に失敗しました"
        case .networkError(let err): return err.localizedDescription
        }
    }
}

// MARK: - API Response Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

// MARK: - APIService
class APIService {
    static let shared = APIService()
    private let baseURL = AppConfig.baseURL

    private var token: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    func setToken(_ token: String) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    var isAuthenticated: Bool { token != nil }

    // MARK: - Request Builder
    func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - Request Performer
    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("不明なエラーが発生しました")
            }
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            let decoded = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            if decoded.success, let result = decoded.data {
                return result
            } else {
                throw APIError.serverError(decoded.error ?? "サーバーエラーが発生しました")
            }
        } catch let error as APIError {
            throw error
        } catch is DecodingError {
            throw APIError.decodingError
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Auth
    func login(email: String, password: String) async throws -> AuthResponse {
        var urlRequest = try makeRequest(path: "/auth/login", method: "POST")
        urlRequest.httpBody = try JSONEncoder().encode(LoginRequest(email: email, password: password))
        return try await perform(urlRequest)
    }

    func register(email: String, password: String, name: String, phone: String?, role: String) async throws -> AuthResponse {
        var urlRequest = try makeRequest(path: "/auth/register", method: "POST")
        urlRequest.httpBody = try JSONEncoder().encode(RegisterRequest(email: email, password: password, name: name, phone: phone, role: role))
        return try await perform(urlRequest)
    }

    // MARK: - Public Properties
    func getPublicProperties() async throws -> [Property] {
        let urlRequest = try makeRequest(path: "/properties/public", method: "GET")
        return try await perform(urlRequest)
    }

    func getPropertyById(_ id: String) async throws -> Property {
        let urlRequest = try makeRequest(path: "/properties/\(id)", method: "GET")
        return try await perform(urlRequest)
    }

    // MARK: - My Properties
    func getMyProperties() async throws -> [Property] {
        let urlRequest = try makeRequest(path: "/properties/my", method: "GET")
        return try await perform(urlRequest)
    }

    func createProperty(name: String, address: String, description: String?, price: Double?, imageData: [(Data, String)] = []) async throws -> Property {
        let boundary = UUID().uuidString
        var urlRequest = try makeRequest(path: "/properties", method: "POST")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ field: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(field)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        append("name", value: name)
        append("address", value: address)
        if let description { append("description", value: description) }
        if let price { append("price", value: String(price)) }

        for (index, (data, mimeType)) in imageData.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        return try await perform(urlRequest)
    }

    func updateProperty(_ id: String, name: String?, address: String?, description: String?, price: Double?) async throws -> Property {
        var urlRequest = try makeRequest(path: "/properties/\(id)", method: "PATCH")
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let address { body["address"] = address }
        if let description { body["description"] = description }
        if let price { body["price"] = price }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(urlRequest)
    }

    func deleteProperty(_ id: String) async throws {
        let urlRequest = try makeRequest(path: "/properties/\(id)", method: "DELETE")
        let _: EmptyResponse = try await perform(urlRequest)
    }

    // MARK: - Public Lands
    func getPublicLands() async throws -> [Land] {
        let urlRequest = try makeRequest(path: "/lands/public", method: "GET")
        return try await perform(urlRequest)
    }

    func getLandById(_ id: String) async throws -> Land {
        let urlRequest = try makeRequest(path: "/lands/\(id)", method: "GET")
        return try await perform(urlRequest)
    }

    // MARK: - My Lands
    func getMyLands() async throws -> [Land] {
        let urlRequest = try makeRequest(path: "/lands/my", method: "GET")
        return try await perform(urlRequest)
    }

    func createLand(name: String, address: String, description: String?, price: Double?, imageData: [(Data, String)] = []) async throws -> Land {
        let boundary = UUID().uuidString
        var urlRequest = try makeRequest(path: "/lands", method: "POST")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ field: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(field)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        append("name", value: name)
        append("address", value: address)
        if let description { append("description", value: description) }
        if let price { append("price", value: String(price)) }

        for (index, (data, mimeType)) in imageData.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        return try await perform(urlRequest)
    }

    func updateLand(_ id: String, name: String?, address: String?, description: String?, price: Double?) async throws -> Land {
        var urlRequest = try makeRequest(path: "/lands/\(id)", method: "PATCH")
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let address { body["address"] = address }
        if let description { body["description"] = description }
        if let price { body["price"] = price }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(urlRequest)
    }

    func deleteLand(_ id: String) async throws {
        let urlRequest = try makeRequest(path: "/lands/\(id)", method: "DELETE")
        let _: EmptyResponse = try await perform(urlRequest)
    }

    // MARK: - Inquiries
    func submitInquiry(request: InquiryRequest) async throws -> PurchaseInquiry {
        var urlRequest = try makeRequest(path: "/inquiries", method: "POST")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        return try await perform(urlRequest)
    }

    // MARK: - Sale Listing Requests
    func submitSaleRequest(
        type: String,
        propertyId: String? = nil,
        landId: String? = nil,
        askingPrice: Double? = nil,
        description: String? = nil,
        contactInfo: String? = nil,
        imageData: [(Data, String)] = [] // [(imageData, mimeType)]
    ) async throws -> SaleListingRequest {
        // Multipart form data upload
        let boundary = UUID().uuidString
        var urlRequest = try makeRequest(path: "/sale-requests", method: "POST")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ field: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(field)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        append("type", value: type)
        if let propertyId { append("propertyId", value: propertyId) }
        if let landId { append("landId", value: landId) }
        if let askingPrice { append("askingPrice", value: String(askingPrice)) }
        if let description { append("description", value: description) }
        if let contactInfo { append("contactInfo", value: contactInfo) }

        for (index, (data, mimeType)) in imageData.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        return try await perform(urlRequest)
    }

    func getMySaleRequests() async throws -> [SaleListingRequest] {
        let urlRequest = try makeRequest(path: "/sale-requests/my", method: "GET")
        return try await perform(urlRequest)
    }

    // MARK: - ユーザー設定（プリファレンス）
    func getUserPreference() async throws -> UserPreference {
        let request = try makeRequest(path: "/preferences", method: "GET")
        return try await perform(request)
    }

    func updateUserPreference(displayMode: String?, displayPrefectures: [String]?, preferredRegions: [String]?) async throws -> UserPreference {
        var body: [String: Any] = [:]
        if let displayMode { body["displayMode"] = displayMode }
        if let displayPrefectures { body["displayPrefectures"] = displayPrefectures }
        if let preferredRegions { body["preferredRegions"] = preferredRegions }
        var request = try makeRequest(path: "/preferences", method: "PUT")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    func updateUserProfile(name: String?, phone: String?, address: String?, bio: String?, prefecture: String?, prefectures: [String]?) async throws -> User {
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let phone { body["phone"] = phone }
        if let address { body["address"] = address }
        if let bio { body["bio"] = bio }
        if let prefecture { body["prefecture"] = prefecture }
        if let prefectures { body["prefectures"] = prefectures }
        var request = try makeRequest(path: "/users/me", method: "PUT")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    // MARK: - 従業員
    func getEmployees() async throws -> [Employee] {
        let request = try makeRequest(path: "/employees", method: "GET")
        return try await perform(request)
    }

    func getEmployee(id: String) async throws -> Employee {
        let request = try makeRequest(path: "/employees/\(id)", method: "GET")
        return try await perform(request)
    }

    func createEmployee(data: [String: Any]) async throws -> Employee {
        var request = try makeRequest(path: "/employees", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        return try await perform(request)
    }

    func updateEmployee(id: String, data: [String: Any]) async throws -> Employee {
        var request = try makeRequest(path: "/employees/\(id)", method: "PUT")
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        return try await perform(request)
    }
}

// MARK: - Empty Response Helper
struct EmptyResponse: Decodable {}
