import SwiftUI

struct VendorDetailView: View {
    let vendor: Vendor
    @StateObject private var vm = VendorViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondaryBlue.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.largeTitle).foregroundColor(.secondaryBlue)
                        )
                    Text(vendor.name).font(.title2).fontWeight(.bold).foregroundColor(.textDark)
                    Text(vm.categoryLabel(vendor.category)).font(.subheadline).foregroundColor(.textGray)
                    if let rating = vendor.rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                    .foregroundColor(.warningOrange)
                            }
                            Text(String(format: "%.1f", rating)).font(.subheadline).foregroundColor(.textGray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Contact info
                VStack(spacing: 12) {
                    if let contact = vendor.contactName {
                        DetailRow(label: "担当者", value: contact, icon: "person.fill")
                    }
                    if let email = vendor.email {
                        DetailRow(label: "メール", value: email, icon: "envelope.fill")
                    }
                    if let phone = vendor.phoneNumber {
                        DetailRow(label: "電話", value: phone, icon: "phone.fill")
                    }
                    if let address = vendor.address {
                        DetailRow(label: "住所", value: address, icon: "mappin.circle.fill")
                    }
                    if let website = vendor.website {
                        DetailRow(label: "ウェブサイト", value: website, icon: "globe")
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Specialties & certifications
                if !vendor.specialties.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("専門分野").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(vendor.specialties, id: \.self) { spec in
                                Text(spec)
                                    .font(.caption)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.accentBlue.opacity(0.1))
                                    .foregroundColor(.accentBlue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !vendor.certifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("資格・認定").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        ForEach(vendor.certifications, id: \.self) { cert in
                            Label(cert, systemImage: "checkmark.seal.fill")
                                .font(.subheadline).foregroundColor(.successGreen)
                        }
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let desc = vendor.description, !desc.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("概要").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        Text(desc).font(.body).foregroundColor(.textDark)
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("業者詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
