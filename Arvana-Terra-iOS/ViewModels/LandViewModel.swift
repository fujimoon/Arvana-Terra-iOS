import Foundation
import SwiftUI

@MainActor
class LandViewModel: ObservableObject {
    @Published var publicLands: [Land] = []
    @Published var myLands: [Land] = []
    @Published var selectedLand: Land?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchPublicLands() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            publicLands = try await apiService.getPublicLands()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMyLands() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            myLands = try await apiService.getMyLands()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchLandById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedLand = try await apiService.getLandById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createLand(name: String, address: String, area: Double, zoning: String?, status: String, isPublic: Bool, purchasePrice: Double?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreateLandRequest(
                name: name, address: address, area: area,
                zoning: zoning, status: status, isPublic: isPublic,
                purchasePrice: purchasePrice, notes: notes
            )
            let newLand = try await apiService.createLand(request)
            myLands.insert(newLand, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateLand(_ id: String, name: String?, address: String?, status: String?, isPublic: Bool?, currentValue: Double?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = UpdateLandRequest(
                name: name, address: address, area: nil,
                zoning: nil, status: status, isPublic: isPublic,
                currentValue: currentValue, notes: notes
            )
            let updated = try await apiService.updateLand(id, request)
            if let idx = myLands.firstIndex(where: { $0.id == id }) {
                myLands[idx] = updated
            }
            selectedLand = updated
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteLand(_ id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await apiService.deleteLand(id)
            myLands.removeAll { $0.id == id }
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
