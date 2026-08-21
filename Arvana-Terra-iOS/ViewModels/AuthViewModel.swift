import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Login fields
    @Published var loginEmail = ""
    @Published var loginPassword = ""

    // Register fields
    @Published var registerName = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerPhone = ""
    @Published var registerRole = "homeowner"

    init() {
        // Check for persisted token
        if APIService.shared.isAuthenticated {
            isLoggedIn = true
            // Restore user info if saved
            if let data = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: data) {
                currentUser = user
            }
        }
    }

    func login() async {
        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.login(email: loginEmail, password: loginPassword)
            APIService.shared.setToken(response.token)
            currentUser = response.user
            if let data = try? JSONEncoder().encode(response.user) {
                UserDefaults.standard.set(data, forKey: "currentUser")
            }
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func register() async {
        guard !registerName.isEmpty, !registerEmail.isEmpty, registerPassword.count >= 8 else {
            errorMessage = "全ての必須項目を入力してください（パスワードは8文字以上）"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.register(
                email: registerEmail,
                password: registerPassword,
                name: registerName,
                phone: registerPhone.isEmpty ? nil : registerPhone,
                role: registerRole
            )
            APIService.shared.setToken(response.token)
            currentUser = response.user
            if let data = try? JSONEncoder().encode(response.user) {
                UserDefaults.standard.set(data, forKey: "currentUser")
            }
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        APIService.shared.clearToken()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        currentUser = nil
        isLoggedIn = false
        loginEmail = ""
        loginPassword = ""
    }
}
