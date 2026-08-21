import Foundation
import SwiftUI

@MainActor
class EquipmentViewModel: ObservableObject {
    @Published var equipmentList: [Equipment] = []
    @Published var selectedEquipment: Equipment?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchEquipment(propertyId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            equipmentList = try await apiService.getEquipment(propertyId: propertyId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchEquipmentById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedEquipment = try await apiService.getEquipmentById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createEquipment(propertyId: String, roomId: String?, name: String, category: String, manufacturer: String?, model: String?, status: String, installationDate: String?, warrantyExpiry: String?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreateEquipmentRequest(
                propertyId: propertyId, roomId: roomId,
                name: name, category: category,
                manufacturer: manufacturer, model: model,
                serialNumber: nil, installationDate: installationDate,
                warrantyExpiry: warrantyExpiry, status: status, notes: notes
            )
            let newEquipment = try await apiService.createEquipment(request)
            equipmentList.insert(newEquipment, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateEquipment(_ id: String, status: String?, lastMaintenanceDate: String?, nextMaintenanceDate: String?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = UpdateEquipmentRequest(
                name: nil, category: nil, manufacturer: nil,
                model: nil, serialNumber: nil,
                status: status,
                lastMaintenanceDate: lastMaintenanceDate,
                nextMaintenanceDate: nextMaintenanceDate,
                notes: notes
            )
            let updated = try await apiService.updateEquipment(id, request)
            if let idx = equipmentList.firstIndex(where: { $0.id == id }) {
                equipmentList[idx] = updated
            }
            selectedEquipment = updated
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    var equipmentByCategory: [String: [Equipment]] {
        Dictionary(grouping: equipmentList, by: { $0.category })
    }

    var equipmentByFloor: [Int: [Equipment]] {
        let roomEquipment = equipmentList.filter { $0.roomId != nil }
        return Dictionary(grouping: roomEquipment, by: { _ in 1 }) // Simplified
    }

    func statusColor(for status: String) -> SwiftUI.Color {
        switch status.lowercased() {
        case "active", "normal", "good": return .successGreen
        case "maintenance", "warning": return .warningOrange
        case "broken", "error", "inactive": return .errorRed
        default: return .textGray
        }
    }
}
