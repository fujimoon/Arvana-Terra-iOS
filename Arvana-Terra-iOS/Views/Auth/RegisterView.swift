import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("お名前 *").font(.subheadline).fontWeight(.medium)
                        TextField("山田 太郎", text: $authVM.registerName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("メールアドレス *").font(.subheadline).fontWeight(.medium)
                        TextField("email@example.com", text: $authVM.registerEmail)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("パスワード * (8文字以上)").font(.subheadline).fontWeight(.medium)
                        SecureField("パスワード", text: $authVM.registerPassword)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("電話番号").font(.subheadline).fontWeight(.medium)
                        TextField("090-0000-0000", text: $authVM.registerPhone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("アカウント種別 *").font(.subheadline).fontWeight(.medium)
                        Picker("種別", selection: $authVM.registerRole) {
                            Text("住宅オーナー").tag("homeowner")
                            Text("土地オーナー").tag("landlord")
                        }
                        .pickerStyle(.segmented)
                    }

                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(Color.errorRed)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await authVM.register() }
                    } label: {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("登録する").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryNavy)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(authVM.isLoading)
                }
                .padding()
            }
            .navigationTitle("新規登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}
