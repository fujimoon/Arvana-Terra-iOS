import Foundation
import PhotosUI
import SwiftUI

@MainActor
class SaleRequestViewModel: ObservableObject {
    @Published var askingPrice = ""
    @Published var description = ""
    @Published var contactInfo = ""
    @Published var selectedImages: [UIImage] = []
    @Published var isSubmitting = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var mySaleRequests: [SaleListingRequest] = []

    func submit(type: String, propertyId: String? = nil, landId: String? = nil) async {
        guard !selectedImages.isEmpty else {
            errorMessage = "画像を1枚以上選択してください"
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            let imageData = selectedImages.compactMap { image -> (Data, String)? in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                return (data, "image/jpeg")
            }
            _ = try await APIService.shared.submitSaleRequest(
                type: type,
                propertyId: propertyId,
                landId: landId,
                askingPrice: Double(askingPrice),
                description: description.isEmpty ? nil : description,
                contactInfo: contactInfo.isEmpty ? nil : contactInfo,
                imageData: imageData
            )
            isSuccess = true
        } catch {
            errorMessage = "申請に失敗しました。もう一度お試しください。"
        }
        isSubmitting = false
    }

    func loadMySaleRequests() async {
        do {
            mySaleRequests = try await APIService.shared.getMySaleRequests()
        } catch {
            // silent fail
        }
    }
}
