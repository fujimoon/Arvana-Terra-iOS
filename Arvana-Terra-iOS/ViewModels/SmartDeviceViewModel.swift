import Foundation
import SwiftUI

@MainActor
class SmartDeviceViewModel: ObservableObject {
    @Published var devices: [SmartDeviceData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchDevices(propertyId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            devices = try await apiService.getSmartDevices(propertyId: propertyId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createDevice(propertyId: String, request: CreateSmartDeviceRequest) async -> Bool {
        do {
            let newDevice = try await apiService.createSmartDevice(propertyId: propertyId, request: request)
            devices.insert(newDevice, at: 0)
            return true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deviceTypeLabel(_ type: String) -> String {
        switch type {
        case "water_meter": return "水道メーター"
        case "electric_meter": return "電気メーター"
        case "camera": return "カメラ"
        case "sensor": return "センサー"
        default: return type
        }
    }

    func deviceTypeIcon(_ type: String) -> String {
        switch type {
        case "water_meter": return "drop.fill"
        case "electric_meter": return "bolt.fill"
        case "camera": return "camera.fill"
        case "sensor": return "antenna.radiowaves.left.and.right"
        default: return "cpu"
        }
    }

    func cameraStatusLabel(_ status: String?) -> String {
        switch status {
        case "active": return "正常"
        case "inactive": return "停止中"
        case "error": return "エラー"
        default: return ""
        }
    }

    func cameraStatusColor(_ status: String?) -> Color {
        switch status {
        case "active": return .successGreen
        case "inactive": return .textGray
        case "error": return .errorRed
        default: return .textGray
        }
    }

    var errorCount: Int { devices.filter { $0.cameraStatus == "error" }.count }
    var cameraCount: Int { devices.filter { $0.deviceType == "camera" }.count }
}
