import SwiftUI
import PhotosUI

struct PropertySaleRequestView: View {
    let propertyId: String
    let propertyName: String
    let thumbnailUrl: String?
    @StateObject private var viewModel = SaleRequestViewModel()
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Property context card
                    HStack(spacing: 12) {
                        if let url = thumbnailUrl.flatMap(URL.init) {
                            AsyncImage(url: url) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.borderGray
                            }
                            .frame(width: 60, height: 60).cornerRadius(8).clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.borderGray)
                                .frame(width: 60, height: 60)
                                .overlay(Image(systemName: "house").foregroundColor(Color.textGray))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(propertyName).font(.headline).foregroundColor(Color.textDark)
                            Text("物件").font(.caption).foregroundColor(Color.textGray)
                        }
                    }

                    // Info banner
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(Color.accentBlue)
                        Text("申請内容をARVANA管理者が精査し、承認されると売り出し中一覧に公開されます。")
                            .font(.caption).foregroundColor(Color.textGray)
                    }
                    .padding(12).background(Color.accentBlue.opacity(0.05)).cornerRadius(8)

                    if viewModel.isSuccess {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60)).foregroundColor(Color.successGreen)
                            Text("申請を受け付けました").font(.title2).fontWeight(.bold)
                            Text("管理者の審査後に公開されます。").foregroundColor(Color.textGray)
                            Button("閉じる") { dismiss() }.buttonStyle(.borderedProminent).tint(Color.primaryNavy)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 40)
                    } else {
                        Group {
                            // Asking price
                            VStack(alignment: .leading, spacing: 8) {
                                Text("希望売出し価格（万円）").font(.subheadline).fontWeight(.medium)
                                HStack {
                                    TextField("0", text: $viewModel.askingPrice)
                                        .textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                                    Text("万円").foregroundColor(Color.textGray)
                                }
                            }
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("物件の説明・特徴").font(.subheadline).fontWeight(.medium)
                                TextEditor(text: $viewModel.description)
                                    .frame(minHeight: 100).padding(4)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.borderGray))
                            }
                            // Contact info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("連絡先情報").font(.subheadline).fontWeight(.medium)
                                TextField("追加の連絡先等", text: $viewModel.contactInfo)
                                    .textFieldStyle(.roundedBorder)
                            }
                            // Image picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("画像 * (1枚以上必須、1枚目がサムネール)").font(.subheadline).fontWeight(.medium)
                                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 10, matching: .images) {
                                    Label("画像を選択", systemImage: "photo.on.rectangle.angled")
                                        .frame(maxWidth: .infinity).padding()
                                        .background(Color.borderGray.opacity(0.5)).cornerRadius(8)
                                }
                                .onChange(of: photoPickerItems) { items in
                                    Task {
                                        viewModel.selectedImages = []
                                        for item in items {
                                            if let data = try? await item.loadTransferable(type: Data.self),
                                               let image = UIImage(data: data) {
                                                viewModel.selectedImages.append(image)
                                            }
                                        }
                                    }
                                }
                                // Preview
                                if !viewModel.selectedImages.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(viewModel.selectedImages.indices, id: \.self) { i in
                                                ZStack(alignment: .topLeading) {
                                                    Image(uiImage: viewModel.selectedImages[i])
                                                        .resizable().aspectRatio(contentMode: .fill)
                                                        .frame(width: 80, height: 80).cornerRadius(8).clipped()
                                                    if i == 0 {
                                                        Text("表紙").font(.caption2).padding(2)
                                                            .background(Color.primaryNavy).foregroundColor(.white)
                                                            .cornerRadius(4).padding(2)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if let error = viewModel.errorMessage {
                            Text(error).foregroundColor(Color.errorRed).font(.caption)
                        }
                        Button {
                            Task { await viewModel.submit(type: "property", propertyId: propertyId) }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("売出し希望を申請する").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding().background(Color.primaryNavy)
                        .foregroundColor(.white).cornerRadius(12).disabled(viewModel.isSubmitting)
                    }
                }
                .padding()
            }
            .navigationTitle("物件売出し希望申請")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") { dismiss() }
                }
            }
        }
    }
}
