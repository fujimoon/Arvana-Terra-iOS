import Foundation
import Combine

// MARK: - ChatService
class ChatService: ObservableObject {
    static let shared = ChatService()
    private let baseURL = AppConfig.baseURL

    // APIService と同じパターン：URLRequest を組み立てる
    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // APIService.perform と同じパターン：APIResponse<T> でデコード
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
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

    // MARK: - チャットルーム一覧取得
    func getChatRooms(type: String, targetId: String) async throws -> [ChatRoom] {
        guard var components = URLComponents(string: baseURL + "/chats") else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "targetId", value: targetId)
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return try await perform(request)
    }

    // MARK: - チャットルーム作成
    func createChatRoom(type: String, title: String, description: String?, targetId: String) async throws -> ChatRoom {
        var request = try makeRequest(path: "/chats", method: "POST")
        var body: [String: Any] = [
            "type": type,
            "title": title
        ]
        if let description, !description.isEmpty {
            body["description"] = description
        }
        if type == "land" { body["landId"] = targetId }
        else if type == "property" { body["propertyId"] = targetId }
        else if type == "employee" { body["employeeId"] = targetId }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    // MARK: - ルーム詳細取得
    func getChatRoom(id: String) async throws -> ChatRoom {
        let request = try makeRequest(path: "/chats/\(id)", method: "GET")
        return try await perform(request)
    }

    // MARK: - メッセージ一覧取得
    func getMessages(roomId: String, page: Int = 1) async throws -> [ChatMessage] {
        guard var components = URLComponents(string: baseURL + "/chats/\(roomId)/messages") else {
            throw APIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "50")
        ]
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // レスポンスが { success, data: { messages: [...], total: n } } の場合
        if let wrapper = try? await performRaw(request, as: APIResponse<ChatMessagesResponse>.self) {
            return wrapper.data?.messages ?? []
        }
        // フォールバック: { success, data: [...] } の配列形式
        return try await perform(request)
    }

    // MARK: - メッセージ送信
    func sendMessage(roomId: String, content: String) async throws -> ChatMessage {
        var request = try makeRequest(path: "/chats/\(roomId)/messages", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["content": content])
        return try await perform(request)
    }

    // MARK: - 生デコードヘルパー（エラーを throws しない）
    private func performRaw<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(type, from: data)
    }
}
