import SwiftUI

struct MyLandListView: View {
    @StateObject private var viewModel = LandViewModel()
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.myLands.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map.slash")
                            .font(.system(size: 48))
                            .foregroundColor(Color.borderGray)
                        Text("登録されている土地がありません")
                            .foregroundColor(Color.textGray)
                        Button("土地を登録する") {
                            showingCreate = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.primaryNavy)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.myLands) { land in
                            NavigationLink(destination: LandManageView(land: land, viewModel: viewModel)) {
                                LandRowView(land: land)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let id = viewModel.myLands[index].id
                                Task { await viewModel.deleteLand(id) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("マイ土地")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadMyLands()
            }
            .sheet(isPresented: $showingCreate) {
                LandCreateView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadMyLands()
        }
    }
}
