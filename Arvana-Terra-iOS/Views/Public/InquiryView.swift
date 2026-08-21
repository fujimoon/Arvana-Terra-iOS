import SwiftUI

// MARK: - Property Inquiry View
struct PropertyInquiryView: View {
    let propertyId: String
    let propertyName: String
    @StateObject private var viewModel = InquiryViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Context header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("お問い合わせ対象")
                            .font(.caption)
                            .foregroundColor(Color.textGray)
                        Text(propertyName)
                            .font(.headline)
                            .foregroundColor(Color.textDark)
                    }
                    .padding()
                    .background(Color.accentBlue.opacity(0.05))
                    .cornerRadius(8)

                    if viewModel.isSuccess {
                        // Success state
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.successGreen)
                            Text("お問い合わせを送信しました")
                                .font(.title2).fontWeight(.bold)
                            Text("担当者よりご連絡いたします。")
                                .foregroundColor(Color.textGray)
                            Button("閉じる") { dismiss() }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.primaryNavy)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Form fields
                        Group {
                            // inquiryType picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("お問い合わせ種別 *").font(.subheadline).fontWeight(.medium)
                                Picker("種別", selection: $viewModel.inquiryType) {
                                    Text("購入希望").tag("purchase")
                                    Text("相談希望").tag("consultation")
                                }
                                .pickerStyle(.segmented)
                            }

                            // senderName
                            VStack(alignment: .leading, spacing: 8) {
                                Text("お名前 *").font(.subheadline).fontWeight(.medium)
                                TextField("山田 太郎", text: $viewModel.senderName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            // senderEmail
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メールアドレス *").font(.subheadline).fontWeight(.medium)
                                TextField("email@example.com", text: $viewModel.senderEmail)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }

                            // senderPhone
                            VStack(alignment: .leading, spacing: 8) {
                                Text("電話番号").font(.subheadline).fontWeight(.medium)
                                TextField("090-0000-0000", text: $viewModel.senderPhone)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.phonePad)
                            }

                            // message
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メッセージ * (10文字以上)").font(.subheadline).fontWeight(.medium)
                                TextEditor(text: $viewModel.message)
                                    .frame(minHeight: 120)
                                    .padding(4)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.borderGray))
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error).foregroundColor(Color.errorRed).font(.caption)
                        }

                        Button {
                            Task { await viewModel.submit(type: "property", propertyId: propertyId) }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("送信する").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryNavy)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(viewModel.isSubmitting)
                    }
                }
                .padding()
            }
            .navigationTitle("購入・相談のお問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Land Inquiry View
struct LandInquiryView: View {
    let landId: String
    let landName: String
    @StateObject private var viewModel = InquiryViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("お問い合わせ対象").font(.caption).foregroundColor(Color.textGray)
                        Text(landName).font(.headline).foregroundColor(Color.textDark)
                    }
                    .padding()
                    .background(Color.accentBlue.opacity(0.05))
                    .cornerRadius(8)

                    if viewModel.isSuccess {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(Color.successGreen)
                            Text("お問い合わせを送信しました").font(.title2).fontWeight(.bold)
                            Text("担当者よりご連絡いたします。").foregroundColor(Color.textGray)
                            Button("閉じる") { dismiss() }.buttonStyle(.borderedProminent).tint(Color.primaryNavy)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 40)
                    } else {
                        Group {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("お問い合わせ種別 *").font(.subheadline).fontWeight(.medium)
                                Picker("種別", selection: $viewModel.inquiryType) {
                                    Text("購入希望").tag("purchase")
                                    Text("相談希望").tag("consultation")
                                }.pickerStyle(.segmented)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("お名前 *").font(.subheadline).fontWeight(.medium)
                                TextField("山田 太郎", text: $viewModel.senderName).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メールアドレス *").font(.subheadline).fontWeight(.medium)
                                TextField("email@example.com", text: $viewModel.senderEmail).textFieldStyle(.roundedBorder).keyboardType(.emailAddress).autocapitalization(.none)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("電話番号").font(.subheadline).fontWeight(.medium)
                                TextField("090-0000-0000", text: $viewModel.senderPhone).textFieldStyle(.roundedBorder).keyboardType(.phonePad)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メッセージ * (10文字以上)").font(.subheadline).fontWeight(.medium)
                                TextEditor(text: $viewModel.message).frame(minHeight: 120).padding(4).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.borderGray))
                            }
                        }
                        if let error = viewModel.errorMessage { Text(error).foregroundColor(Color.errorRed).font(.caption) }
                        Button { Task { await viewModel.submit(type: "land", landId: landId) } } label: {
                            if viewModel.isSubmitting { ProgressView().tint(.white) } else { Text("送信する").fontWeight(.semibold) }
                        }
                        .frame(maxWidth: .infinity).padding().background(Color.primaryNavy).foregroundColor(.white).cornerRadius(12).disabled(viewModel.isSubmitting)
                    }
                }
                .padding()
            }
            .navigationTitle("購入・相談のお問い合わせ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("キャンセル") { dismiss() } } }
        }
    }
}
