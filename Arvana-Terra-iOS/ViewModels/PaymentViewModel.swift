import Foundation
import SwiftUI

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchPayments(propertyId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            payments = try await apiService.getPayments(propertyId: propertyId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPayment(propertyId: String, request: CreatePaymentRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let newPayment = try await apiService.createPayment(propertyId: propertyId, request: request)
            payments.insert(newPayment, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func statusLabel(_ status: String) -> String {
        switch status {
        case "paid": return "支払済"
        case "pending": return "未払"
        case "late": return "遅延"
        case "overdue": return "滞納"
        default: return status
        }
    }

    func statusColor(_ status: String) -> Color {
        switch status {
        case "paid": return .successGreen
        case "pending": return .textGray
        case "late": return .warningOrange
        case "overdue": return .errorRed
        default: return .textGray
        }
    }

    var paidCount: Int { payments.filter { $0.status == "paid" }.count }
    var lateCount: Int { payments.filter { $0.status == "late" || $0.status == "overdue" }.count }
    var totalAmount: Double { payments.reduce(0) { $0 + $1.amount } }
}
