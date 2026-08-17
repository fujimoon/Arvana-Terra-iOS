import SwiftUI

struct PublicPropertyListView: View {
    @StateObject private var vm = PropertyViewModel()
    @State private var searchText = ""

    var filteredProperties: [Property] {
        if searchText.isEmpty { return vm.publicProperties }
        return vm.publicProperties.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if vm.isLoading {
                LoadingView()
            } else if let error = vm.errorMessage {
                ErrorView(message: error) {
                    Task { await vm.fetchPublicProperties() }
                }
            } else if filteredProperties.isEmpty {
                EmptyStateView(
                    title: "物件が見つかりません",
                    message: "公開中の物件はまだありません",
                    systemImage: "building.2"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredProperties) { property in
                            NavigationLink {
                                PublicPropertyDetailView(property: property)
                            } label: {
                                PropertyCard(property: property)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.backgroundGray)
            }
        }
        .navigationTitle("公開物件一覧")
        .searchable(text: $searchText, prompt: "物件名・住所で検索")
        .task { await vm.fetchPublicProperties() }
    }
}
