import Foundation
import SwiftUI
import PhotosUI

@MainActor
class LandViewModel: ObservableObject {
    @Published var publicLands: [Land] = []
    @Published var myLands: [Land] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Create / Edit fields
    @Published var name = ""
    @Published var address = ""
    @Published var description = ""
    @Published var price = ""
    @Published var selectedImages: [UIImage] = []
    @Published var isSubmitting = false
    @Published var isSuccess = false

    func loadPublicLands() async {
        isLoading = true
        errorMessage = nil
        do {
            publicLands = try await APIService.shared.getPublicLands()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMyLands() async {
        isLoading = true
        errorMessage = nil
        do {
            myLands = try await APIService.shared.getMyLands()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createLand() async {
        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = "土地名と住所は必須です"
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            let imageData = selectedImages.compactMap { image -> (Data, String)? in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                return (data, "image/jpeg")
            }
            let created = try await APIService.shared.createLand(
                name: name,
                address: address,
                description: description.isEmpty ? nil : description,
                price: Double(price),
                imageData: imageData
            )
            myLands.insert(created, at: 0)
            isSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteLand(_ id: String) async {
        do {
            try await APIService.shared.deleteLand(id)
            myLands.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetForm() {
        name = ""
        address = ""
        description = ""
        price = ""
        selectedImages = []
        isSuccess = false
        errorMessage = nil
    }
}
