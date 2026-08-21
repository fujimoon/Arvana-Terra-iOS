import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private let socketService = SocketService.shared

    func checkAuthStatus() {
        isAuthenticated = apiService.isAuthenticated
        if isAuthenticated {
            Task {
                await fetchCurrentUser()
            }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authResponse = try await apiService.login(email: email, password: password)
            currentUser = authResponse.user
            isAuthenticated = true

            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                socketService.connect(token: token)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(email: String, password: String, name: String, role: String? = nil, companyName: String? = nil, phoneNumber: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authResponse = try await apiService.register(
                email: email,
                password: password,
                name: name,
                role: role,
                companyName: companyName,
                phoneNumber: phoneNumber
            )
            currentUser = authResponse.user
            isAuthenticated = true

            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                socketService.connect(token: token)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        socketService.disconnect()
        try? await apiService.logout()
        currentUser = nil
        isAuthenticated = false
    }

    private func fetchCurrentUser() async {
        do {
            currentUser = try await apiService.getCurrentUser()
        } catch APIError.unauthorized {
            apiService.clearTokens()
            isAuthenticated = false
        } catch {
            print("AuthViewModel: Failed to fetch current user - \(error.localizedDescription)")
        }
    }
}
