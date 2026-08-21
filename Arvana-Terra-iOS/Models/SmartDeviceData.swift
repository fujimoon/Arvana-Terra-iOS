import Foundation

struct SmartDeviceData: Codable, Identifiable {
    let id: String
    let propertyId: String
    let roomId: String?
    let deviceType: String
    let deviceId: String
    let location: String?
    let readings: [DeviceReading]
    let cameraStatus: String?
    let lastUpdated: String
    let room: PaymentRoomSummary?
}

struct DeviceReading: Codable {
    let date: String
    let value: Double
}

struct CreateSmartDeviceRequest: Codable {
    let deviceType: String
    let deviceId: String
    let roomId: String?
    let location: String?
    let cameraStatus: String?
}
