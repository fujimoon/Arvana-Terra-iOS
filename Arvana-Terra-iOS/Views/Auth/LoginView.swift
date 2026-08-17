import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showRegister = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.primaryNavy, Color.secondaryBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    // Logo section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 96, height: 96)
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.system(size: 52))
                                .foregroundColor(.white)
                        }

                        Text("Arvana Terra")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("不動産資産管理プラットフォーム")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Login form
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            // Email field
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.textGray)
                                    .frame(width: 20)
                                TextField("メールアドレス", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Password field
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.textGray)
                                    .frame(width: 20)
                                if showPassword {
                                    TextField("パスワード", text: $password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("パスワード", text: $password)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.textGray)
                                }
                            }
                            .padding()
                            .background(Color.surfaceWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Error message
                        if let errorMessage = authVM.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.errorRed)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.errorRed)
                            }
                            .padding(.horizontal)
                        }

                        // Login button
                        Button(action: {
                            Task { await authVM.login(email: email, password: password) }
                        }) {
                            HStack {
                                if authVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("ログイン")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                authVM.isLoading || email.isEmpty || password.isEmpty
                                ? Color.white.opacity(0.5)
                                : Color.white
                            )
                            .foregroundColor(.primaryNavy)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)

                        // Register link
                        Button(action: { showRegister = true }) {
                            Text("アカウントをお持ちでない方は")
                                .foregroundColor(.white.opacity(0.8))
                            + Text(" 新規登録")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authVM)
        }
    }
}
