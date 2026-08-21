import Foundation
import SwiftUI
import PhotosUI

@MainActor
class PropertyViewModel: ObservableObject {
    @Published var publicProperties: [Property] = []
    @Published var myProperties: [Property] = []
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

    func loadPublicProperties() async {
        isLoading = true
        errorMessage = nil
        do {
            publicProperties = try await APIService.shared.getPublicProperties()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMyProperties() async {
        isLoading = true
        errorMessage = nil
        do {
            myProperties = try await APIService.shared.getMyProperties()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createProperty() async {
        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = "物件名と住所は必須です"
            return
        }
        isSubmitting = true
        errorMessage = nil
        do {
            let imageData = selectedImages.compactMap { image -> (Data, String)? in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                return (data, "image/jpeg")
            }
            let created = try await APIService.shared.createProperty(
                name: name,
                address: address,
                description: description.isEmpty ? nil : description,
                price: Double(price),
                imageData: imageData
            )
            myProperties.insert(created, at: 0)
            isSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteProperty(_ id: String) async {
        do {
            try await APIService.shared.deleteProperty(id)
            myProperties.removeAll { $0.id == id }
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
