import SwiftUI

struct PrefectureSelectorView: View {
    @Binding var selected: [String]
    var label: String = "都道府県"
    var singleSelection: Bool = false

    let prefectures = AppConfig.prefectures
    let columns = [GridItem(.adaptive(minimum: 80))]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.textDark)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(prefectures, id: \.self) { prefecture in
                    let isSelected = selected.contains(prefecture)
                    Button(action: {
                        if singleSelection {
                            selected = [prefecture]
                        } else {
                            if isSelected {
                                selected.removeAll { $0 == prefecture }
                            } else {
                                selected.append(prefecture)
                            }
                        }
                    }) {
                        Text(prefecture)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isSelected ? Color.primaryNavy : Color(.systemGray6))
                            .foregroundColor(isSelected ? .white : Color.textGray)
                            .cornerRadius(12)
                    }
                }
            }

            if !selected.isEmpty {
                Text("選択中: \(selected.joined(separator: "、"))")
                    .font(.caption2)
                    .foregroundColor(Color.textGray)
            }
        }
    }
}
