import Foundation
import SwiftUI

@MainActor
class ValuationViewModel: ObservableObject {
    @Published var valuations: [AssetValuation] = []
    @Published var calculationResult: CalculateValuationResponse?
    @Published var isLoading = false
    @Published var isCalculating = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchValuations(propertyId: String? = nil, landId: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            valuations = try await apiService.getValuation(propertyId: propertyId, landId: landId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func calculateValuation(propertyId: String?, landId: String?, area: Double, location: String, buildingType: String?, yearBuilt: Int?, condition: String?) async {
        isCalculating = true
        errorMessage = nil
        defer { isCalculating = false }
        do {
            let request = CalculateValuationRequest(
                propertyId: propertyId, landId: landId,
                area: area, location: location,
                buildingType: buildingType,
                yearBuilt: yearBuilt, condition: condition
            )
            calculationResult = try await apiService.calculateValuation(request)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "¥\(formatted)"
    }

    func confidenceLabel(_ confidence: String) -> String {
        switch confidence {
        case "high": return "高精度"
        case "medium": return "中精度"
        case "low": return "低精度"
        default: return confidence
        }
    }

    func confidenceColor(_ confidence: String) -> SwiftUI.Color {
        switch confidence {
        case "high": return .successGreen
        case "medium": return .warningOrange
        case "low": return .errorRed
        default: return .textGray
        }
    }
}
