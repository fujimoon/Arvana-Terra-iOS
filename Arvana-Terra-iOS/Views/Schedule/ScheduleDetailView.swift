import SwiftUI

struct ScheduleDetailView: View {
    let schedule: Schedule
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category Badge
                    HStack {
                        Text(schedule.categoryLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(schedule.categoryColor.opacity(0.15))
                            .foregroundColor(schedule.categoryColor)
                            .cornerRadius(20)
                        if schedule.isCompleted {
                            Label("完了", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }

                    // Title
                    Text(schedule.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#1B3A6B"))
                        .strikethrough(schedule.isCompleted)

                    // Date/Time
                    let df = ISO8601DateFormatter()
                    if let start = df.date(from: schedule.startDateTime),
                       let end = df.date(from: schedule.endDateTime) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label {
                                if schedule.isAllDay {
                                    Text(start.formatted(.dateTime.year().month().day().weekday(.wide)))
                                } else {
                                    VStack(alignment: .leading) {
                                        Text(start.formatted(.dateTime.year().month().day().weekday(.wide).hour().minute()))
                                        Text("〜 " + end.formatted(.dateTime.year().month().day().weekday(.wide).hour().minute()))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundColor(Color(hex: "#4A90D9"))
                            }
                        }
                    }

                    // Related entities
                    if let p = schedule.relatedProperty {
                        Label(p.name, systemImage: "building.2")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let l = schedule.relatedLand {
                        Label(l.name, systemImage: "map")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let r = schedule.relatedRoom {
                        Label(r.name, systemImage: "door.left.hand.open")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Description
                    if let desc = schedule.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    Divider()

                    // Actions
                    VStack(spacing: 10) {
                        if !schedule.isCompleted {
                            Button {
                                onComplete()
                                dismiss()
                            } label: {
                                Label("完了にする", systemImage: "checkmark.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(12)
                            }
                        }

                        Button {
                            onEdit()
                            dismiss()
                        } label: {
                            Label("編集", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#1B3A6B").opacity(0.1))
                                .foregroundColor(Color(hex: "#1B3A6B"))
                                .cornerRadius(12)
                        }

                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("削除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("予定の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
