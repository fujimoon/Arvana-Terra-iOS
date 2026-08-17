import SwiftUI

struct EmployeeDetailView: View {
    let employee: Employee
    @StateObject private var vm = EmployeeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.accentBlue.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(employee.name.prefix(1)))
                                .font(.largeTitle).fontWeight(.bold).foregroundColor(.primaryNavy)
                        )
                    Text(employee.name).font(.title2).fontWeight(.bold).foregroundColor(.textDark)
                    if let dept = employee.department, let pos = employee.position {
                        Text("\(dept) · \(pos)").font(.subheadline).foregroundColor(.textGray)
                    }
                    HStack(spacing: 8) {
                        Circle()
                            .fill(employee.status == "active" ? Color.successGreen : Color.textGray)
                            .frame(width: 8, height: 8)
                        Text(employee.status == "active" ? "在籍中" : "退職")
                            .font(.caption).foregroundColor(.textGray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Contact info
                VStack(spacing: 12) {
                    DetailRow(label: "メール", value: employee.email, icon: "envelope.fill")
                    if let phone = employee.phoneNumber {
                        DetailRow(label: "電話", value: phone, icon: "phone.fill")
                    }
                    if let type = employee.employmentType {
                        DetailRow(label: "雇用形態", value: vm.employmentTypeLabel(type), icon: "briefcase.fill")
                    }
                    if let start = employee.startDate {
                        DetailRow(label: "入社日", value: formatDate(start), icon: "calendar")
                    }
                }
                .padding(16)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Chat button
                NavigationLink {
                    EmployeeChatView(employee: employee)
                } label: {
                    Label("メッセージを送る", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryNavy)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let notes = employee.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("備考").font(.subheadline).fontWeight(.semibold).foregroundColor(.textGray)
                        Text(notes).font(.body).foregroundColor(.textDark)
                    }
                    .padding(16)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .background(Color.backgroundGray)
        .navigationTitle("従業員詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    func formatDate(_ dateString: String) -> String {
        let fmt = ISO8601DateFormatter()
        guard let date = fmt.date(from: dateString) else { return dateString }
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: date)
    }
}

struct EmployeeChatView: View {
    let employee: Employee
    @StateObject private var vm = ChatViewModel()

    var body: some View {
        Group {
            if let roomId = vm.chatRooms.first?.id {
                ChatRoomView(chatRoom: vm.chatRooms.first!)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.accentBlue.opacity(0.5))
                    Text("チャットを開始するには\nチャットルームを作成してください")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.textGray)
                    Button("チャットルームを作成") {
                        Task {
                            await vm.createChatRoom(
                                name: "\(employee.name)とのチャット",
                                roomType: "employee",
                                propertyId: nil, landId: nil,
                                participantIds: employee.userId.map { [$0] } ?? []
                            )
                        }
                    }
                    .padding()
                    .background(Color.primaryNavy)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .navigationTitle("\(employee.name)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchChatRooms() }
    }
}
