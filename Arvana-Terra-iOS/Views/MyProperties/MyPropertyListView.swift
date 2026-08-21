import SwiftUI

struct MyPropertyListView: View {
    @StateObject private var viewModel = PropertyViewModel()
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.myProperties.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "house.slash")
                            .font(.system(size: 48))
                            .foregroundColor(Color.borderGray)
                        Text("登録されている物件がありません")
                            .foregroundColor(Color.textGray)
                        Button("物件を登録する") {
                            showingCreate = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.primaryNavy)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.myProperties) { property in
                            NavigationLink(destination: PropertyManageView(property: property, viewModel: viewModel)) {
                                PropertyRowView(property: property)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let id = viewModel.myProperties[index].id
                                Task { await viewModel.deleteProperty(id) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("マイ物件")
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
                await viewModel.loadMyProperties()
            }
            .sheet(isPresented: $showingCreate) {
                PropertyCreateView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadMyProperties()
        }
    }
}
