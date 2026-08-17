import SwiftUI

struct TaskManageView: View {
    @StateObject private var vm = TaskViewModel()
    @State private var showAdd = false
    @State private var showAISuggest = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("フィルター", selection: $selectedTab) {
                Text("未着手 (\(vm.pendingTasks.count))").tag(0)
                Text("進行中 (\(vm.inProgressTasks.count))").tag(1)
                Text("完了 (\(vm.completedTasks.count))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(12)
            .background(Color.surfaceWhite)

            if vm.isLoading && vm.tasks.isEmpty {
                LoadingView()
            } else {
                let displayTasks = selectedTab == 0 ? vm.pendingTasks : selectedTab == 1 ? vm.inProgressTasks : vm.completedTasks
                if displayTasks.isEmpty {
                    EmptyStateView(
                        title: "タスクなし",
                        message: selectedTab == 0 ? "未着手のタスクはありません" : selectedTab == 1 ? "進行中のタスクはありません" : "完了したタスクはありません",
                        systemImage: selectedTab == 2 ? "checkmark.circle.fill" : "list.bullet",
                        actionTitle: selectedTab == 0 ? "タスクを追加" : nil,
                        action: selectedTab == 0 ? { showAdd = true } : nil
                    )
                } else {
                    List {
                        ForEach(displayTasks) { task in
                            TaskDetailRow(task: task, vm: vm)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("タスク管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showAISuggest = true }) {
                        Image(systemName: "sparkles").foregroundColor(.accentBlue)
                    }
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus").foregroundColor(.primaryNavy)
                    }
                }
            }
        }
        .task { await vm.fetchTasks() }
        .sheet(isPresented: $showAdd) { AddTaskView(vm: vm) }
        .sheet(isPresented: $showAISuggest) { AISuggestView(vm: vm) }
    }
}

struct TaskDetailRow: View {
    let task: Task
    @ObservedObject var vm: TaskViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                let nextStatus = task.status == "pending" ? "in_progress" : "completed"
                Task { await vm.updateTaskStatus(task.id, status: nextStatus) }
            }) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : task.status == "in_progress" ? "circle.dotted" : "circle")
                    .font(.title3)
                    .foregroundColor(task.status == "completed" ? .successGreen : task.status == "in_progress" ? .warningOrange : .textGray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(task.status == "completed" ? .textGray : .textDark)
                    .strikethrough(task.status == "completed")
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(vm.priorityLabel(task.priority), systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(vm.priorityColor(task.priority))

                    if let due = task.dueDate {
                        Label(formatDate(due), systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(isOverdue(due) && task.status != "completed" ? .errorRed : .textGray)
                    }

                    if let assignee = task.assigneeName {
                        Label(assignee, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(.textGray)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }

    func isOverdue(_ dateString: String) -> Bool {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return false }
        return date < Date()
    }
}

struct AddTaskView: View {
    @ObservedObject var vm: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var priority = "medium"
    @State private var category = ""
    @State private var dueDate = Date()
    @State private var useDueDate = false
    @State private var notes = ""

    let priorities = [("high","高"), ("medium","中"), ("low","低")]

    var isValid: Bool { !title.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク情報") {
                    TextField("タイトル *", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 80)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("詳細（任意）").font(.body).foregroundColor(.textGray).padding(4)
                            }
                        }
                }
                Section("優先度・期限") {
                    Picker("優先度", selection: $priority) {
                        ForEach(priorities, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    TextField("カテゴリ", text: $category)
                    Toggle("期限を設定", isOn: $useDueDate)
                    if useDueDate {
                        DatePicker("期限", selection: $dueDate, displayedComponents: .date)
                    }
                }
                Section("メモ") {
                    TextEditor(text: $notes).frame(height: 60)
                }
            }
            .navigationTitle("タスクを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            let fmt = ISO8601DateFormatter()
                            let success = await vm.createTask(
                                title: title, description: description.isEmpty ? nil : description,
                                propertyId: nil, landId: nil, assigneeId: nil,
                                priority: priority,
                                dueDate: useDueDate ? fmt.string(from: dueDate) : nil,
                                category: category.isEmpty ? nil : category,
                                notes: notes.isEmpty ? nil : notes
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(!isValid || vm.isLoading)
                }
            }
        }
    }
}

struct AISuggestView: View {
    @ObservedObject var vm: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var context = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AIタスク提案", systemImage: "sparkles")
                        .font(.headline).foregroundColor(.primaryNavy)
                    Text("現在の状況を入力すると、AIが適切なタスクを提案します")
                        .font(.subheadline).foregroundColor(.textGray)
                    TextEditor(text: $context)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.backgroundGray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: {
                    Task { await vm.fetchAISuggestions(propertyId: nil, landId: nil, context: context) }
                }) {
                    HStack {
                        if vm.isSuggesting {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Label("提案を取得", systemImage: "sparkles")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentBlue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(vm.isSuggesting)

                if !vm.aiSuggestions.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vm.aiSuggestions.indices, id: \.self) { idx in
                                let suggestion = vm.aiSuggestions[idx]
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(suggestion.title).font(.subheadline).fontWeight(.semibold).foregroundColor(.textDark)
                                        Spacer()
                                        Text(vm.priorityLabel(suggestion.priority))
                                            .font(.caption).foregroundColor(vm.priorityColor(suggestion.priority))
                                    }
                                    Text(suggestion.description).font(.caption).foregroundColor(.textGray)
                                    Button("このタスクを追加") {
                                        Task {
                                            await vm.createTask(
                                                title: suggestion.title,
                                                description: suggestion.description,
                                                propertyId: nil, landId: nil, assigneeId: nil,
                                                priority: suggestion.priority,
                                                dueDate: nil, category: suggestion.category, notes: nil
                                            )
                                        }
                                    }
                                    .font(.caption).foregroundColor(.accentBlue)
                                }
                                .padding(12)
                                .background(Color.surfaceWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(Color.backgroundGray)
            .navigationTitle("AIタスク提案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
            }
        }
    }
}
