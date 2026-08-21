import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var companyName = ""
    @State private var phoneNumber = ""
    @State private var selectedRole = "owner"
    @State private var showPassword = false

    let roles = [
        ("owner", "オーナー"),
        ("manager", "管理者"),
        ("tenant", "テナント"),
        ("vendor", "業者")
    ]

    private var passwordsMatch: Bool {
        password == confirmPassword || confirmPassword.isEmpty
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty &&
        password == confirmPassword && password.count >= 8
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.primaryNavy)
                        Text("新規アカウント登録")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textDark)
                    }
                    .padding(.top, 24)

                    // Form
                    VStack(spacing: 16) {
                        FormField(title: "お名前 *", placeholder: "山田 太郎", text: $name, icon: "person.fill")

                        FormField(title: "メールアドレス *", placeholder: "example@email.com", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード * (8文字以上)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textGray)

                            HStack {
                                Image(systemName: "lock.fill").foregroundColor(.textGray).frame(width: 20)
                                if showPassword {
                                    TextField("パスワード", text: $password).autocapitalization(.none).autocorrectionDisabled()
                                } else {
                                    SecureField("パスワード", text: $password)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill").foregroundColor(.textGray)
                                }
                            }
                            .padding()
                            .background(Color.surfaceWhite)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderGray))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード確認 *")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textGray)
                            HStack {
                                Image(systemName: "lock.rotation.fill").foregroundColor(.textGray).frame(width: 20)
                                SecureField("パスワードを再入力", text: $confirmPassword)
                            }
                            .padding()
                            .background(Color.surfaceWhite)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(!passwordsMatch ? Color.errorRed : Color.borderGray))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            if !passwordsMatch {
                                Text("パスワードが一致しません")
                                    .font(.caption)
                                    .foregroundColor(.errorRed)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("役割")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.textGray)
                            Picker("役割", selection: $selectedRole) {
                                ForEach(roles, id: \.0) { role in
                                    Text(role.1).tag(role.0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FormField(title: "会社名", placeholder: "株式会社〇〇", text: $companyName, icon: "building.fill")
                        FormField(title: "電話番号", placeholder: "090-1234-5678", text: $phoneNumber, icon: "phone.fill", keyboardType: .phonePad)
                    }
                    .padding(.horizontal, 20)

                    if let errorMessage = authVM.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.errorRed)
                            Text(errorMessage).font(.caption).foregroundColor(.errorRed)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Register button
                    Button(action: {
                        Task {
                            await authVM.register(
                                email: email,
                                password: password,
                                name: name,
                                role: selectedRole,
                                companyName: companyName.isEmpty ? nil : companyName,
                                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                            )
                            if authVM.isAuthenticated { dismiss() }
                        }
                    }) {
                        HStack {
                            if authVM.isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("登録する").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.primaryNavy : Color.textGray.opacity(0.4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!isFormValid || authVM.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.backgroundGray)
            .navigationTitle("新規登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.textGray)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.textGray)
                    .frame(width: 20)
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                        .autocorrectionDisabled()
                }
            }
            .padding()
            .background(Color.surfaceWhite)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderGray))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
