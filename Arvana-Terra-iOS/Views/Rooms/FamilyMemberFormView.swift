import SwiftUI

struct FamilyMemberFormView: View {
    let tenantId: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var nameKana = ""
    @State private var relationship = ""
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var gender = ""
    @State private var occupation = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("氏名 *", text: $name)
                    TextField("フリガナ", text: $nameKana)
                    TextField("続柄 *（例: 配偶者、子）", text: $relationship)
                    Toggle("生年月日を設定", isOn: $hasBirthDate)
                    if hasBirthDate {
                        DatePicker("生年月日", selection: $birthDate, displayedComponents: .date)
                    }
                    Picker("性別", selection: $gender) {
                        Text("選択なし").tag("")
                        Text("男性").tag("male")
                        Text("女性").tag("female")
                        Text("その他").tag("other")
                    }
                    TextField("職業", text: $occupation)
                }
                Section("メモ") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle("家族情報を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中..." : "追加") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || relationship.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        var data: [String: Any] = [
            "name": name,
            "nameKana": nameKana,
            "relationship": relationship,
            "gender": gender,
            "occupation": occupation,
            "notes": notes,
        ]
        if hasBirthDate {
            data["birthDate"] = ISO8601DateFormatter().string(from: birthDate)
        }
        do {
            _ = try await TenantService.shared.addFamilyMember(tenantId: tenantId, data: data)
            onSaved()
            dismiss()
        } catch {
            print("FamilyMemberFormView save error: \(error)")
        }
    }
}
