import SwiftUI

struct ScheduleFormView: View {
    var initialDate: Date?
    var existing: Schedule?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category = "other"
    @State private var isAllDay = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var reminderOption = ""
    @State private var isSaving = false

    private let reminderOptions: [(String, String)] = [
        ("", "なし"), ("10", "10分前"), ("30", "30分前"), ("60", "1時間前"), ("1440", "1日前"),
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("タイトル", text: $title)
                }

                Section("カテゴリ") {
                    ForEach(ScheduleCategory.allCases, id: \.rawValue) { cat in
                        HStack {
                            Circle().fill(cat.color).frame(width: 10, height: 10)
                            Text(cat.label)
                            Spacer()
                            if category == cat.rawValue {
                                Image(systemName: "checkmark").foregroundColor(Color(hex: "#1B3A6B"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { category = cat.rawValue }
                    }
                }

                Section("日時") {
                    Toggle("終日", isOn: $isAllDay)
                    if isAllDay {
                        DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                        DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                    } else {
                        DatePicker("開始", selection: $startDate)
                        DatePicker("終了", selection: $endDate)
                    }
                }

                Section("リマインダー") {
                    Picker("リマインダー", selection: $reminderOption) {
                        ForEach(reminderOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }

                Section("メモ") {
                    TextEditor(text: $description).frame(minHeight: 80)
                }
            }
            .navigationTitle(existing == nil ? "予定を追加" : "予定を編集")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { populateIfEditing() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中..." : "保存") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func populateIfEditing() {
        if let e = existing {
            title = e.title
            description = e.description ?? ""
            category = e.category
            isAllDay = e.isAllDay
            let df = ISO8601DateFormatter()
            startDate = df.date(from: e.startDateTime) ?? Date()
            endDate = df.date(from: e.endDateTime) ?? Date().addingTimeInterval(3600)
            reminderOption = e.reminderMinutes.map { "\($0)" } ?? ""
        } else if let d = initialDate {
            startDate = d
            endDate = d.addingTimeInterval(3600)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let df = ISO8601DateFormatter()
        var data: [String: Any] = [
            "title": title,
            "description": description,
            "category": category,
            "isAllDay": isAllDay,
            "startDateTime": df.string(from: startDate),
            "endDateTime": df.string(from: endDate),
        ]
        if let mins = Int(reminderOption) { data["reminderMinutes"] = mins }

        do {
            if let id = existing?.id {
                _ = try await ScheduleService.shared.updateSchedule(id: id, data: data)
            } else {
                _ = try await ScheduleService.shared.createSchedule(data: data)
            }
            onSaved()
            dismiss()
        } catch {
            print("Save schedule error: \(error)")
        }
    }
}
