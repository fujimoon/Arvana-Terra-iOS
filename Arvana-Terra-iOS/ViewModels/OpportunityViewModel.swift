import Foundation
import SwiftUI

@MainActor
class OpportunityViewModel: ObservableObject {
    @Published var opportunities: [BusinessOpportunity] = []
    @Published var selectedOpportunity: BusinessOpportunity?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterType: String?

    private let apiService = APIService.shared

    func fetchOpportunities() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            opportunities = try await apiService.getOpportunities()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filteredOpportunities: [BusinessOpportunity] {
        guard let filter = filterType else { return opportunities }
        return opportunities.filter { $0.opportunityType == filter }
    }

    func riskLabel(_ risk: String) -> String {
        switch risk {
        case "low": return "低リスク"
        case "medium": return "中リスク"
        case "high": return "高リスク"
        default: return risk
        }
    }

    func riskColor(_ risk: String) -> SwiftUI.Color {
        switch risk {
        case "low": return .successGreen
        case "medium": return .warningOrange
        case "high": return .errorRed
        default: return .textGray
        }
    }

    func typeLabel(_ type: String) -> String {
        switch type {
        case "purchase": return "購入"
        case "sale": return "売却"
        case "lease": return "賃貸"
        case "development": return "開発"
        case "partnership": return "共同事業"
        default: return type
        }
    }

    func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "未定" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "¥\(formatted)"
    }
}
