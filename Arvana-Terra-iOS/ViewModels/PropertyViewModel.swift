import Foundation
import SwiftUI

@MainActor
class PropertyViewModel: ObservableObject {
    @Published var publicProperties: [Property] = []
    @Published var myProperties: [Property] = []
    @Published var selectedProperty: Property?
    @Published var rooms: [Room] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchPublicProperties() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            publicProperties = try await apiService.getPublicProperties()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMyProperties() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            myProperties = try await apiService.getMyProperties()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchPropertyById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedProperty = try await apiService.getPropertyById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRooms(propertyId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            rooms = try await apiService.getRooms(propertyId: propertyId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createProperty(name: String, address: String, buildingType: String, floors: Int, totalRooms: Int, area: Double, status: String, isPublic: Bool, purchasePrice: Double?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreatePropertyRequest(
                name: name, address: address, buildingType: buildingType,
                floors: floors, totalRooms: totalRooms, area: area,
                status: status, isPublic: isPublic,
                purchasePrice: purchasePrice, notes: notes
            )
            let newProperty = try await apiService.createProperty(request)
            myProperties.insert(newProperty, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateProperty(_ id: String, name: String?, address: String?, status: String?, isPublic: Bool?, currentValue: Double?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = UpdatePropertyRequest(
                name: name, address: address, buildingType: nil,
                floors: nil, totalRooms: nil, area: nil,
                status: status, isPublic: isPublic,
                currentValue: currentValue, notes: notes
            )
            let updated = try await apiService.updateProperty(id, request)
            if let idx = myProperties.firstIndex(where: { $0.id == id }) {
                myProperties[idx] = updated
            }
            selectedProperty = updated
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteProperty(_ id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await apiService.deleteProperty(id)
            myProperties.removeAll { $0.id == id }
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    var occupancyRate: Double {
        guard !rooms.isEmpty else { return 0 }
        let occupied = rooms.filter { $0.status == "occupied" }.count
        return Double(occupied) / Double(rooms.count) * 100
    }
}
