import Foundation
import SwiftUI

@MainActor
class VendorViewModel: ObservableObject {
    @Published var vendors: [Vendor] = []
    @Published var myVendors: [Vendor] = []
    @Published var selectedVendor: Vendor?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchVendors() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            vendors = try await apiService.getVendors()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMyVendors() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            myVendors = try await apiService.getMyVendors()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchVendorById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedVendor = try await apiService.getVendorById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var vendorsByCategory: [String: [Vendor]] {
        Dictionary(grouping: vendors, by: { $0.category })
    }

    func categoryLabel(_ category: String) -> String {
        switch category {
        case "construction": return "建設・工事"
        case "electrical": return "電気工事"
        case "plumbing": return "配管工事"
        case "cleaning": return "清掃"
        case "security": return "セキュリティ"
        case "landscaping": return "造園・緑化"
        case "hvac": return "空調設備"
        case "elevator": return "エレベーター"
        default: return category
        }
    }

    func ratingStars(_ rating: Double?) -> String {
        guard let rating = rating else { return "評価なし" }
        let stars = Int(rating)
        return String(repeating: "★", count: stars) + String(repeating: "☆", count: 5 - stars)
    }
}
