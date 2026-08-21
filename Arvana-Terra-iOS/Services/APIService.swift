import Foundation

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .invalidResponse: return "無効なレスポンスです"
        case .unauthorized: return "認証が必要です"
        case .notFound: return "リソースが見つかりません"
        case .serverError(let code): return "サーバーエラー (\(code))"
        case .decodingError(let error): return "データ解析エラー: \(error.localizedDescription)"
        case .encodingError(let error): return "データ変換エラー: \(error.localizedDescription)"
        case .networkError(let error): return "ネットワークエラー: \(error.localizedDescription)"
        case .unknown: return "不明なエラーです"
        }
    }
}

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let success: Bool
    let data: [T]
    let total: Int?
    let page: Int?
    let limit: Int?
}

// MARK: - APIService
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    private let session: URLSession
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
    }
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refreshToken") }
        set { UserDefaults.standard.set(newValue, forKey: "refreshToken") }
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Token Management
    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
    }

    var isAuthenticated: Bool {
        return accessToken != nil
    }

    // MARK: - Generic Request
    private func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: AppConfig.apiBaseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                // Try token refresh
                if requiresAuth, let newToken = try? await refreshAccessToken() {
                    self.accessToken = newToken
                    return try await request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
                }
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Refresh Token
    private func refreshAccessToken() async throws -> String {
        guard let refresh = refreshToken else { throw APIError.unauthorized }

        guard let url = URL(string: AppConfig.apiBaseURL + "/auth/refresh") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(RefreshTokenRequest(refreshToken: refresh))

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.unauthorized
        }

        let tokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        return tokenResponse.accessToken
    }

    // MARK: - Auth Endpoints
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "/auth/login",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        guard let data = response.data else { throw APIError.invalidResponse }
        saveTokens(accessToken: data.accessToken, refreshToken: data.refreshToken)
        return data
    }

    func register(email: String, password: String, name: String, role: String? = nil, companyName: String? = nil, phoneNumber: String? = nil) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, password: password, name: name, role: role, companyName: companyName, phoneNumber: phoneNumber)
        let response: APIResponse<AuthResponse> = try await request(
            endpoint: "/auth/register",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        guard let data = response.data else { throw APIError.invalidResponse }
        saveTokens(accessToken: data.accessToken, refreshToken: data.refreshToken)
        return data
    }

    func logout() async throws {
        let _: APIResponse<EmptyResponse> = try await request(endpoint: "/auth/logout", method: "POST")
        clearTokens()
    }

    func getCurrentUser() async throws -> User {
        let response: APIResponse<User> = try await request(endpoint: "/auth/me")
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Land Endpoints
    func getPublicLands() async throws -> [Land] {
        let response: PaginatedResponse<Land> = try await request(endpoint: "/lands/public", requiresAuth: false)
        return response.data
    }

    func getMyLands() async throws -> [Land] {
        let response: PaginatedResponse<Land> = try await request(endpoint: "/lands/my")
        return response.data
    }

    func getLandById(_ id: String) async throws -> Land {
        let response: APIResponse<Land> = try await request(endpoint: "/lands/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func createLand(_ request: CreateLandRequest) async throws -> Land {
        let response: APIResponse<Land> = try await request(endpoint: "/lands", method: "POST", body: request)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func updateLand(_ id: String, _ request: UpdateLandRequest) async throws -> Land {
        let response: APIResponse<Land> = try await request(endpoint: "/lands/\(id)", method: "PUT", body: request)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func deleteLand(_ id: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(endpoint: "/lands/\(id)", method: "DELETE")
    }

    // MARK: - Property Endpoints
    func getPublicProperties() async throws -> [Property] {
        let response: PaginatedResponse<Property> = try await request(endpoint: "/properties/public", requiresAuth: false)
        return response.data
    }

    func getMyProperties() async throws -> [Property] {
        let response: PaginatedResponse<Property> = try await request(endpoint: "/properties/my")
        return response.data
    }

    func getPropertyById(_ id: String) async throws -> Property {
        let response: APIResponse<Property> = try await request(endpoint: "/properties/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func createProperty(_ body: CreatePropertyRequest) async throws -> Property {
        let response: APIResponse<Property> = try await request(endpoint: "/properties", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func updateProperty(_ id: String, _ body: UpdatePropertyRequest) async throws -> Property {
        let response: APIResponse<Property> = try await request(endpoint: "/properties/\(id)", method: "PUT", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func deleteProperty(_ id: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(endpoint: "/properties/\(id)", method: "DELETE")
    }

    // MARK: - Room Endpoints
    func getRooms(propertyId: String) async throws -> [Room] {
        let response: PaginatedResponse<Room> = try await request(endpoint: "/properties/\(propertyId)/rooms")
        return response.data
    }

    func getRoomById(_ id: String) async throws -> Room {
        let response: APIResponse<Room> = try await request(endpoint: "/rooms/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func createRoom(_ body: CreateRoomRequest) async throws -> Room {
        let response: APIResponse<Room> = try await request(endpoint: "/rooms", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func updateRoom(_ id: String, _ body: UpdateRoomRequest) async throws -> Room {
        let response: APIResponse<Room> = try await request(endpoint: "/rooms/\(id)", method: "PUT", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Equipment Endpoints
    func getEquipment(propertyId: String) async throws -> [Equipment] {
        let response: PaginatedResponse<Equipment> = try await request(endpoint: "/properties/\(propertyId)/equipment")
        return response.data
    }

    func getEquipmentById(_ id: String) async throws -> Equipment {
        let response: APIResponse<Equipment> = try await request(endpoint: "/equipment/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func createEquipment(_ body: CreateEquipmentRequest) async throws -> Equipment {
        let response: APIResponse<Equipment> = try await request(endpoint: "/equipment", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func updateEquipment(_ id: String, _ body: UpdateEquipmentRequest) async throws -> Equipment {
        let response: APIResponse<Equipment> = try await request(endpoint: "/equipment/\(id)", method: "PUT", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Contract Endpoints
    func getContracts() async throws -> [Contract] {
        let response: PaginatedResponse<Contract> = try await request(endpoint: "/contracts")
        return response.data
    }

    func getContractById(_ id: String) async throws -> Contract {
        let response: APIResponse<Contract> = try await request(endpoint: "/contracts/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func createContract(_ body: CreateContractRequest) async throws -> Contract {
        let response: APIResponse<Contract> = try await request(endpoint: "/contracts", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func updateContract(_ id: String, _ body: UpdateContractRequest) async throws -> Contract {
        let response: APIResponse<Contract> = try await request(endpoint: "/contracts/\(id)", method: "PUT", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Chat Endpoints
    func getChatRooms() async throws -> [ChatRoom] {
        let response: PaginatedResponse<ChatRoom> = try await request(endpoint: "/chat/rooms")
        return response.data
    }

    func getChatMessages(roomId: String) async throws -> [ChatMessage] {
        let response: PaginatedResponse<ChatMessage> = try await request(endpoint: "/chat/rooms/\(roomId)/messages")
        return response.data
    }

    func sendMessage(roomId: String, content: String, messageType: String = "text") async throws -> ChatMessage {
        let body = SendMessageRequest(content: content, messageType: messageType)
        let response: APIResponse<ChatMessage> = try await request(endpoint: "/chat/rooms/\(roomId)/messages", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func createChatRoom(_ body: CreateChatRoomRequest) async throws -> ChatRoom {
        let response: APIResponse<ChatRoom> = try await request(endpoint: "/chat/rooms", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Task Endpoints
    func getTasks(propertyId: String? = nil, landId: String? = nil) async throws -> [Task] {
        var endpoint = "/tasks"
        var queryItems: [String] = []
        if let pid = propertyId { queryItems.append("propertyId=\(pid)") }
        if let lid = landId { queryItems.append("landId=\(lid)") }
        if !queryItems.isEmpty { endpoint += "?" + queryItems.joined(separator: "&") }
        let response: PaginatedResponse<Task> = try await request(endpoint: endpoint)
        return response.data
    }

    func createTask(_ body: CreateTaskRequest) async throws -> Task {
        let response: APIResponse<Task> = try await request(endpoint: "/tasks", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func updateTask(_ id: String, _ body: UpdateTaskRequest) async throws -> Task {
        let response: APIResponse<Task> = try await request(endpoint: "/tasks/\(id)", method: "PUT", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func aiSuggestTasks(_ body: AISuggestTasksRequest) async throws -> AISuggestTasksResponse {
        let response: APIResponse<AISuggestTasksResponse> = try await request(endpoint: "/tasks/ai-suggest", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Employee Endpoints
    func getEmployees() async throws -> [Employee] {
        let response: PaginatedResponse<Employee> = try await request(endpoint: "/employees")
        return response.data
    }

    func getEmployeeById(_ id: String) async throws -> Employee {
        let response: APIResponse<Employee> = try await request(endpoint: "/employees/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    // MARK: - Vendor Endpoints
    func getVendors() async throws -> [Vendor] {
        let response: PaginatedResponse<Vendor> = try await request(endpoint: "/vendors")
        return response.data
    }

    func getVendorById(_ id: String) async throws -> Vendor {
        let response: APIResponse<Vendor> = try await request(endpoint: "/vendors/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func getMyVendors() async throws -> [Vendor] {
        let response: PaginatedResponse<Vendor> = try await request(endpoint: "/vendors/my")
        return response.data
    }

    // MARK: - SNS Endpoints
    func getPosts(category: String? = nil) async throws -> [SnsPost] {
        var endpoint = "/sns/posts"
        if let cat = category { endpoint += "?category=\(cat)" }
        let response: PaginatedResponse<SnsPost> = try await request(endpoint: endpoint)
        return response.data
    }

    func getPostById(_ id: String) async throws -> SnsPost {
        let response: APIResponse<SnsPost> = try await request(endpoint: "/sns/posts/\(id)")
        guard let data = response.data else { throw APIError.notFound }
        return data
    }

    func createPost(_ body: CreatePostRequest) async throws -> SnsPost {
        let response: APIResponse<SnsPost> = try await request(endpoint: "/sns/posts", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    func likePost(_ id: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(endpoint: "/sns/posts/\(id)/like", method: "POST")
    }

    func getComments(postId: String) async throws -> [SnsComment] {
        let response: PaginatedResponse<SnsComment> = try await request(endpoint: "/sns/posts/\(postId)/comments")
        return response.data
    }

    func createComment(postId: String, content: String) async throws -> SnsComment {
        let body = CreateCommentRequest(content: content)
        let response: APIResponse<SnsComment> = try await request(endpoint: "/sns/posts/\(postId)/comments", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }

    // MARK: - Opportunity Endpoints
    func getOpportunities() async throws -> [BusinessOpportunity] {
        let response: PaginatedResponse<BusinessOpportunity> = try await request(endpoint: "/opportunities")
        return response.data
    }

    // MARK: - Valuation Endpoints
    func getValuation(propertyId: String? = nil, landId: String? = nil) async throws -> [AssetValuation] {
        var endpoint = "/valuations"
        var queryItems: [String] = []
        if let pid = propertyId { queryItems.append("propertyId=\(pid)") }
        if let lid = landId { queryItems.append("landId=\(lid)") }
        if !queryItems.isEmpty { endpoint += "?" + queryItems.joined(separator: "&") }
        let response: PaginatedResponse<AssetValuation> = try await request(endpoint: endpoint)
        return response.data
    }

    func calculateValuation(_ body: CalculateValuationRequest) async throws -> CalculateValuationResponse {
        let response: APIResponse<CalculateValuationResponse> = try await request(endpoint: "/valuations/calculate", method: "POST", body: body)
        guard let data = response.data else { throw APIError.invalidResponse }
        return data
    }
}

// MARK: - Empty Response Helper
struct EmptyResponse: Codable {}
