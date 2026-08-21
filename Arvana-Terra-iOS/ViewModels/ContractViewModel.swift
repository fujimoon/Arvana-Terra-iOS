import Foundation
import SwiftUI

@MainActor
class ContractViewModel: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var selectedContract: Contract?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchContracts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            contracts = try await apiService.getContracts()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchContractById(_ id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            selectedContract = try await apiService.getContractById(id)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createContract(propertyId: String?, landId: String?, roomId: String?, contractType: String, tenantName: String, tenantContact: String?, tenantEmail: String?, startDate: String, endDate: String, rentAmount: Double?, depositAmount: Double?, notes: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = CreateContractRequest(
                propertyId: propertyId, landId: landId, roomId: roomId,
                contractType: contractType, tenantName: tenantName,
                tenantContact: tenantContact, tenantEmail: tenantEmail,
                startDate: startDate, endDate: endDate,
                rentAmount: rentAmount, depositAmount: depositAmount,
                notes: notes
            )
            let newContract = try await apiService.createContract(request)
            contracts.insert(newContract, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateContractStatus(_ id: String, status: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let request = UpdateContractRequest(
                tenantName: nil, tenantContact: nil, tenantEmail: nil,
                startDate: nil, endDate: nil,
                rentAmount: nil, depositAmount: nil,
                status: status, notes: nil
            )
            let updated = try await apiService.updateContract(id, request)
            if let idx = contracts.firstIndex(where: { $0.id == id }) {
                contracts[idx] = updated
            }
            selectedContract = updated
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    var activeContracts: [Contract] {
        contracts.filter { $0.status == "active" }
    }

    var expiringContracts: [Contract] {
        let formatter = ISO8601DateFormatter()
        let now = Date()
        let thirtyDays = now.addingTimeInterval(30 * 24 * 3600)
        return contracts.filter { contract in
            guard let endDate = formatter.date(from: contract.endDate) else { return false }
            return endDate > now && endDate <= thirtyDays
        }
    }

    func statusLabel(_ status: String) -> String {
        switch status {
        case "active": return "有効"
        case "expired": return "期限切れ"
        case "terminated": return "解除"
        case "pending": return "保留中"
        default: return status
        }
    }

    func statusColor(_ status: String) -> SwiftUI.Color {
        switch status {
        case "active": return .successGreen
        case "expired", "terminated": return .errorRed
        case "pending": return .warningOrange
        default: return .textGray
        }
    }
}
