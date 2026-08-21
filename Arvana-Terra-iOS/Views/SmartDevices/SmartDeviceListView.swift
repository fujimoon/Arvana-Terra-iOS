import SwiftUI

struct SmartDeviceListView: View {
    let propertyId: String
    @StateObject private var vm = SmartDeviceViewModel()
    @State private var showAdd = false

    var body: some View {
        VStack(spacing: 0) {
            // Summary
            HStack(spacing: 12) {
                SummaryBox(title: "総台数", value: "\(vm.devices.count)台", color: .primaryNavy)
                SummaryBox(title: "カメラ", value: "\(vm.cameraCount)台", color: .accentBlue)
                SummaryBox(title: "エラー", value: "\(vm.errorCount)件", color: vm.errorCount > 0 ? .errorRed : .successGreen)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.surfaceWhite)

            if vm.isLoading && vm.devices.isEmpty {
                LoadingView()
            } else if vm.devices.isEmpty {
                EmptyStateView(
                    title: "デバイスなし",
                    message: "スマートデバイスを追加してください",
                    systemImage: "sensor.tag.radiowaves.forward",
                    actionTitle: "デバイスを追加",
                    action: { showAdd = true }
                )
            } else {
                List {
                    ForEach(vm.devices) { device in
                        DeviceRow(device: device, vm: vm)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("スマートデバイス")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus").foregroundColor(.primaryNavy)
                }
            }
        }
        .task { await vm.fetchDevices(propertyId: propertyId) }
        .sheet(isPresented: $showAdd) {
            AddSmartDeviceView(vm: vm, propertyId: propertyId)
        }
    }
}

struct DeviceRow: View {
    let device: SmartDeviceData
    @ObservedObject var vm: SmartDeviceViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primaryNavy.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: vm.deviceTypeIcon(device.deviceType))
                        .foregroundColor(.primaryNavy)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.deviceId)
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                    Spacer()
                    if let status = device.cameraStatus {
                        Text(vm.cameraStatusLabel(status))
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(vm.cameraStatusColor(status))
                    }
                }
                Text(vm.deviceTypeLabel(device.deviceType))
                    .font(.caption).foregroundColor(.textGray)
                if let location = device.location {
                    Text("📍 \(location)")
                        .font(.caption2).foregroundColor(.textGray)
                }
                if let latest = device.readings.last {
                    Text("計測値: \(String(format: "%.1f", latest.value))")
                        .font(.caption2).foregroundColor(.textGray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSmartDeviceView: View {
    @ObservedObject var vm: SmartDeviceViewModel
    let propertyId: String
    @Environment(\.dismiss) private var dismiss

    @State private var deviceType = "sensor"
    @State private var deviceId = ""
    @State private var location = ""
    @State private var cameraStatus = "active"

    let deviceTypes = [
        ("water_meter", "水道メーター"),
        ("electric_meter", "電気メーター"),
        ("camera", "カメラ"),
        ("sensor", "センサー")
    ]
    let cameraStatuses = [("active","正常"), ("inactive","停止中"), ("error","エラー")]

    var isValid: Bool { !deviceId.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("デバイス情報") {
                    Picker("種別", selection: $deviceType) {
                        ForEach(deviceTypes, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    TextField("デバイスID *", text: $deviceId)
                        .autocapitalization(.none)
                    TextField("設置場所", text: $location)
                }
                if deviceType == "camera" {
                    Section("カメラ状態") {
                        Picker("状態", selection: $cameraStatus) {
                            ForEach(cameraStatuses, id: \.0) { Text($0.1).tag($0.0) }
                        }
                    }
                }
            }
            .navigationTitle("デバイスを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let request = CreateSmartDeviceRequest(
                                deviceType: deviceType,
                                deviceId: deviceId,
                                roomId: nil,
                                location: location.isEmpty ? nil : location,
                                cameraStatus: deviceType == "camera" ? cameraStatus : nil
                            )
                            let success = await vm.createDevice(propertyId: propertyId, request: request)
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
