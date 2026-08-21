import SwiftUI

struct PaymentPropertySelectorView: View {
    @StateObject private var propertyVM = PropertyViewModel()

    var body: some View {
        Group {
            if propertyVM.isLoading && propertyVM.myProperties.isEmpty {
                LoadingView()
            } else if propertyVM.myProperties.isEmpty {
                EmptyStateView(
                    title: "物件なし",
                    message: "物件を登録してください",
                    systemImage: "building.2",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                List(propertyVM.myProperties) { property in
                    NavigationLink(property.name) {
                        PaymentListView(propertyId: property.id)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("入金管理 - 物件選択")
        .navigationBarTitleDisplayMode(.inline)
        .task { await propertyVM.fetchMyProperties() }
    }
}

struct SmartDevicePropertySelectorView: View {
    @StateObject private var propertyVM = PropertyViewModel()

    var body: some View {
        Group {
            if propertyVM.isLoading && propertyVM.myProperties.isEmpty {
                LoadingView()
            } else if propertyVM.myProperties.isEmpty {
                EmptyStateView(
                    title: "物件なし",
                    message: "物件を登録してください",
                    systemImage: "building.2",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                List(propertyVM.myProperties) { property in
                    NavigationLink(property.name) {
                        SmartDeviceListView(propertyId: property.id)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("スマートデバイス - 物件選択")
        .navigationBarTitleDisplayMode(.inline)
        .task { await propertyVM.fetchMyProperties() }
    }
}
