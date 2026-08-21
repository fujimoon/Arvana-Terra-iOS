import Foundation

@MainActor
class InquiryViewModel: ObservableObject {
    @Published var senderName = ""
    @Published var senderEmail = ""
    @Published var senderPhone = ""
    @Published var inquiryType = "purchase"
    @Published var message = ""
    @Published var isSubmitting = false
    @Published var isSuccess = false
    @Published var errorMessage: String?

    func submit(type: String, propertyId: String? = nil, landId: String? = nil) async {
        guard !senderName.isEmpty, !senderEmail.isEmpty, message.count >= 10 else {
            errorMessage = "必須項目を正しく入力してください（メッセージは10文字以上）"
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            let request = InquiryRequest(
                type: type,
                propertyId: propertyId,
                landId: landId,
                senderName: senderName,
                senderEmail: senderEmail,
                senderPhone: senderPhone.isEmpty ? nil : senderPhone,
                inquiryType: inquiryType,
                message: message
            )
            _ = try await APIService.shared.submitInquiry(request: request)
            isSuccess = true
        } catch {
            errorMessage = "送信に失敗しました。もう一度お試しください。"
        }
        isSubmitting = false
    }
}
