import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "house.and.flag.fill")
                            .font(.system(size: 56))
                            .foregroundColor(Color.primaryNavy)
                        Text("ARVANA Terra")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(Color.primaryNavy)
                        Text("不動産管理プラットフォーム")
                            .font(.subheadline)
                            .foregroundColor(Color.textGray)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス").font(.subheadline).fontWeight(.medium)
                            TextField("email@example.com", text: $authVM.loginEmail)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード").font(.subheadline).fontWeight(.medium)
                            SecureField("パスワード", text: $authVM.loginPassword)
                                .textFieldStyle(.roundedBorder)
                        }

                        if let error = authVM.errorMessage {
                            Text(error)
                                .foregroundColor(Color.errorRed)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await authVM.login() }
                        } label: {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("ログイン").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryNavy)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(authVM.isLoading)
                    }
                    .padding(.horizontal)

                    // Register link
                    Button("アカウントをお持ちでない方はこちら") {
                        showRegister = true
                    }
                    .foregroundColor(Color.secondaryBlue)
                    .font(.subheadline)
                }
                .padding()
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
        }
    }
}
