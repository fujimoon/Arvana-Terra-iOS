import SwiftUI
import PhotosUI

struct PropertyCreateView: View {
    @ObservedObject var viewModel: PropertyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var photoPickerItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isSuccess {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.successGreen)
                            Text("物件を登録しました")
                                .font(.title2).fontWeight(.bold)
                            Button("閉じる") {
                                viewModel.resetForm()
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.primaryNavy)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        Group {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("物件名 *").font(.subheadline).fontWeight(.medium)
                                TextField("物件名を入力", text: $viewModel.name)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("住所 *").font(.subheadline).fontWeight(.medium)
                                TextField("住所を入力", text: $viewModel.address)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("説明").font(.subheadline).fontWeight(.medium)
                                TextEditor(text: $viewModel.description)
                                    .frame(minHeight: 100)
                                    .padding(4)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.borderGray))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("価格（万円）").font(.subheadline).fontWeight(.medium)
                                HStack {
                                    TextField("0", text: $viewModel.price)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                    Text("万円").foregroundColor(Color.textGray)
                                }
                            }

                            // Image picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("画像 (1枚目がサムネール)").font(.subheadline).fontWeight(.medium)
                                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 10, matching: .images) {
                                    Label("画像を選択", systemImage: "photo.on.rectangle.angled")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.borderGray.opacity(0.5))
                                        .cornerRadius(8)
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
                            Task { await viewModel.createProperty() }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("登録する").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryNavy)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(viewModel.isSubmitting)
                    }
                }
                .padding()
            }
            .navigationTitle("物件を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.resetForm()
                        dismiss()
                    }
                }
            }
        }
    }
}
