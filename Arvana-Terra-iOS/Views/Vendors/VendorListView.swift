import SwiftUI

struct VendorListView: View {
    @StateObject private var vm = VendorViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: String?

    var filteredVendors: [Vendor] {
        var vendors = vm.vendors
        if let cat = selectedCategory { vendors = vendors.filter { $0.category == cat } }
        if !searchText.isEmpty {
            vendors = vendors.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        return vendors
    }

    var categories: [String] { Array(Set(vm.vendors.map { $0.category })).sorted() }

    var body: some View {
        VStack(spacing: 0) {
            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "すべて", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(categories, id: \.self) { cat in
                            FilterChip(title: vm.categoryLabel(cat), isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .background(Color.surfaceWhite)
            }

            if vm.isLoading && vm.vendors.isEmpty {
                LoadingView()
            } else if filteredVendors.isEmpty {
                EmptyStateView(title: "業者なし", message: "業者が登録されていません", systemImage: "person.text.rectangle")
            } else {
                List {
                    ForEach(filteredVendors) { vendor in
                        NavigationLink {
                            VendorDetailView(vendor: vendor)
                        } label: {
                            VendorRow(vendor: vendor, vm: vm)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("業者一覧")
        .searchable(text: $searchText, prompt: "業者名で検索")
        .task { await vm.fetchVendors() }
    }
}

struct VendorRow: View {
    let vendor: Vendor
    @ObservedObject var vm: VendorViewModel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondaryBlue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundColor(.secondaryBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(vendor.name).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                Text(vm.categoryLabel(vendor.category)).font(.caption).foregroundColor(.textGray)
                if let rating = vendor.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.warningOrange)
                        }
                        Text(String(format: "%.1f", rating))
                            .font(.caption2).foregroundColor(.textGray)
                    }
                }
            }
            Spacer()
            StatusBadge(status: vendor.status, type: .generic)
        }
    }
}
