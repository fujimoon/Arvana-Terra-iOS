import SwiftUI

struct PublicLandListView: View {
    @StateObject private var vm = LandViewModel()
    @State private var searchText = ""

    var filteredLands: [Land] {
        if searchText.isEmpty { return vm.publicLands }
        return vm.publicLands.filter {
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
                    Task { await vm.fetchPublicLands() }
                }
            } else if filteredLands.isEmpty {
                EmptyStateView(
                    title: "土地が見つかりません",
                    message: "公開中の土地はまだありません",
                    systemImage: "map"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredLands) { land in
                            NavigationLink {
                                PublicLandDetailView(land: land)
                            } label: {
                                LandCard(land: land)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.backgroundGray)
            }
        }
        .navigationTitle("公開土地一覧")
        .searchable(text: $searchText, prompt: "土地名・住所で検索")
        .task { await vm.fetchPublicLands() }
    }
}
