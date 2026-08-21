import SwiftUI

struct RoomFormView: View {
    let propertyId: String
    var existingRoom: Room? = nil
    let onSaved: (Room) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var floor = ""
    @State private var area = ""
    @State private var roomType = ""
    @State private var rentAmount = ""
    @State private var status = "vacant"
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section("部屋情報") {
                    TextField("部屋名・号室（例: 101号室）", text: $name)
                    TextField("階数", text: $floor).keyboardType(.numberPad)
                    TextField("面積（m2）", text: $area).keyboardType(.decimalPad)
                    TextField("間取り（例: 1LDK）", text: $roomType)
                    TextField("月額賃料（円）", text: $rentAmount).keyboardType(.numberPad)
                    Picker("状態", selection: $status) {
                        Text("空室").tag("vacant")
                        Text("入居中").tag("occupied")
                        Text("メンテナンス").tag("maintenance")
                    }
                }
                Section("メモ・所見") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle(existingRoom == nil ? "部屋を追加" : "部屋を編集")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let r = existingRoom {
                    name = r.name
                    floor = r.floor.map { "\($0)" } ?? ""
                    area = r.area.map { "\($0)" } ?? ""
                    roomType = r.roomType ?? ""
                    rentAmount = r.rentAmount.map { "\(Int($0))" } ?? ""
                    status = r.status
                    notes = r.notes ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中..." : "保存") { Task { await save() } }
                        .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        var data: [String: Any] = [
            "name": name,
            "status": status,
            "notes": notes,
            "roomType": roomType,
        ]
        if let f = Int(floor) { data["floor"] = f }
        if let a = Double(area) { data["area"] = a }
        if let r = Double(rentAmount) { data["rentAmount"] = r }
        do {
            let room: Room
            if let id = existingRoom?.id {
                room = try await RoomService.shared.updateRoom(id: id, data: data)
            } else {
                room = try await RoomService.shared.createRoom(propertyId: propertyId, data: data)
            }
            onSaved(room)
            dismiss()
        } catch {
            print("Save room error: \(error)")
        }
    }
}
