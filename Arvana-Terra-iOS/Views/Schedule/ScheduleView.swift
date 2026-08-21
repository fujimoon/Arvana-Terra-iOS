import SwiftUI

struct ScheduleView: View {
    @State private var schedules: [Schedule] = []
    @State private var upcomingSchedules: [Schedule] = []
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedDate: Date? = nil
    @State private var showingAddSheet = false
    @State private var editingSchedule: Schedule? = nil
    @State private var detailSchedule: Schedule? = nil
    @State private var filterCategory: String = ""
    @State private var isLoading = false

    private let calendar = Calendar.current
    private let today = Date()

    var filteredSchedules: [Schedule] {
        guard !filterCategory.isEmpty else { return schedules }
        return schedules.filter { $0.category == filterCategory }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(label: "すべて", isSelected: filterCategory.isEmpty) {
                            filterCategory = ""
                        }
                        ForEach(ScheduleCategory.allCases, id: \.rawValue) { cat in
                            CategoryFilterChip(
                                label: cat.label,
                                color: cat.color,
                                isSelected: filterCategory == cat.rawValue
                            ) {
                                filterCategory = filterCategory == cat.rawValue ? "" : cat.rawValue
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))

                ScrollView {
                    VStack(spacing: 16) {
                        // Calendar Card
                        VStack(spacing: 0) {
                            // Month Navigation
                            HStack {
                                Button { prevMonth() } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(Color(hex: "#1B3A6B"))
                                }
                                Spacer()
                                Text("\(currentYear)年\(currentMonth)月")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#1B3A6B"))
                                Button("今日") { goToToday() }
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#1B3A6B"))
                                    .padding(.leading, 8)
                                Spacer()
                                Button { nextMonth() } label: {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#1B3A6B"))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)

                            // Weekday Headers
                            let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
                            HStack(spacing: 0) {
                                ForEach(Array(weekdays.enumerated()), id: \.offset) { idx, day in
                                    Text(day)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(idx == 0 ? .red : idx == 6 ? .blue : .secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)

                            // Calendar Grid
                            let days = calendarDays()
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                                ForEach(Array(days.enumerated()), id: \.offset) { idx, date in
                                    if let date = date {
                                        DayCell(
                                            date: date,
                                            events: eventsForDay(date),
                                            isToday: calendar.isDateInToday(date),
                                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                                            weekdayIndex: idx % 7
                                        ) {
                                            selectedDate = calendar.isDate(selectedDate ?? Date.distantPast, inSameDayAs: date) ? nil : date
                                        }
                                    } else {
                                        Color.clear.frame(height: 60)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)

                        // Selected Day Events or Upcoming
                        if let selected = selectedDate {
                            let dayEvents = eventsForDay(selected).filter { filterCategory.isEmpty || $0.category == filterCategory }
                            SelectedDaySection(
                                date: selected,
                                events: dayEvents,
                                onEventTap: { detailSchedule = $0 },
                                onAdd: { editingSchedule = nil; showingAddSheet = true }
                            )
                        } else {
                            UpcomingSection(
                                schedules: upcomingSchedules,
                                onEventTap: { detailSchedule = $0 }
                            )
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("スケジュール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingSchedule = nil
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                ScheduleFormView(
                    initialDate: selectedDate,
                    existing: editingSchedule
                ) {
                    Task { await loadData() }
                }
            }
            .sheet(item: $detailSchedule) { schedule in
                ScheduleDetailView(schedule: schedule, onEdit: {
                    editingSchedule = schedule
                    detailSchedule = nil
                    showingAddSheet = true
                }, onDelete: {
                    Task {
                        try? await ScheduleService.shared.deleteSchedule(id: schedule.id)
                        await loadData()
                    }
                    detailSchedule = nil
                }, onComplete: {
                    Task {
                        try? await ScheduleService.shared.completeSchedule(id: schedule.id)
                        await loadData()
                    }
                    detailSchedule = nil
                })
            }
            .task { await loadData() }
            .onChange(of: currentYear) { _ in Task { await loadData() } }
            .onChange(of: currentMonth) { _ in Task { await loadData() } }
        }
    }

    private func loadData() async {
        async let s = ScheduleService.shared.getSchedules(year: currentYear, month: currentMonth)
        async let u = ScheduleService.shared.getUpcoming(limit: 10)
        schedules = (try? await s) ?? []
        upcomingSchedules = (try? await u) ?? []
    }

    private func calendarDays() -> [Date?] {
        let components = DateComponents(year: currentYear, month: currentMonth, day: 1)
        guard let firstDay = calendar.date(from: components) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay) - 1 // 0=Sun
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDay)!.count
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for d in 1...daysInMonth {
            days.append(calendar.date(byAdding: .day, value: d - 1, to: firstDay))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func eventsForDay(_ date: Date) -> [Schedule] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return filteredSchedules.filter { s in
            guard let start = s.startDate else { return false }
            let end = ISO8601DateFormatter().date(from: s.endDateTime) ?? start
            return start < dayEnd && end >= dayStart
        }
    }

    private func prevMonth() {
        if currentMonth == 1 { currentYear -= 1; currentMonth = 12 }
        else { currentMonth -= 1 }
        selectedDate = nil
    }

    private func nextMonth() {
        if currentMonth == 12 { currentYear += 1; currentMonth = 1 }
        else { currentMonth += 1 }
        selectedDate = nil
    }

    private func goToToday() {
        currentYear = calendar.component(.year, from: today)
        currentMonth = calendar.component(.month, from: today)
        selectedDate = today
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let events: [Schedule]
    let isToday: Bool
    let isSelected: Bool
    let weekdayIndex: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    if isToday {
                        Circle().fill(Color(hex: "#1B3A6B")).frame(width: 28, height: 28)
                    } else if isSelected {
                        Circle().fill(Color(hex: "#4A90D9").opacity(0.2)).frame(width: 28, height: 28)
                    }
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            isToday ? .white :
                            weekdayIndex == 0 ? .red :
                            weekdayIndex == 6 ? .blue :
                            .primary
                        )
                }

                HStack(spacing: 2) {
                    ForEach(Array(events.prefix(3).enumerated()), id: \.offset) { _, ev in
                        Circle()
                            .fill(ev.categoryColor)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isSelected && !isToday ? Color(hex: "#4A90D9").opacity(0.05) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let label: String
    var color: Color = Color(hex: "#1B3A6B")
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .secondary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Day Section

struct SelectedDaySection: View {
    let date: Date
    let events: [Schedule]
    let onEventTap: (Schedule) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date.formatted(.dateTime.month().day().weekday()))
                    .font(.headline)
                    .foregroundColor(Color(hex: "#1B3A6B"))
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color(hex: "#4A90D9"))
                }
            }
            .padding(.horizontal)

            if events.isEmpty {
                Text("この日の予定はありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(events) { event in
                    EventRow(event: event).onTapGesture { onEventTap(event) }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Upcoming Section

struct UpcomingSection: View {
    let schedules: [Schedule]
    let onEventTap: (Schedule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("直近の予定")
                .font(.headline)
                .foregroundColor(Color(hex: "#1B3A6B"))
                .padding(.horizontal)

            if schedules.isEmpty {
                Text("予定はありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(schedules) { event in
                    EventRow(event: event, showDate: true).onTapGesture { onEventTap(event) }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: Schedule
    var showDate: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(event.categoryColor)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(event.isCompleted)
                    .foregroundColor(event.isCompleted ? .secondary : .primary)

                if showDate, let date = event.startDate {
                    Text(date.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !event.isAllDay, let date = event.startDate {
                    Text(date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(event.categoryLabel)
                    .font(.system(size: 11))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(event.categoryColor.opacity(0.15))
                    .foregroundColor(event.categoryColor)
                    .cornerRadius(6)
            }

            Spacer()

            if event.isCompleted {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}
