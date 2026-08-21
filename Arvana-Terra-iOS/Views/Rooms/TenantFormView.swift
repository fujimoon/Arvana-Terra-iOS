import SwiftUI

struct TenantFormView: View {
    let roomId: String
    var existingTenant: Tenant? = nil
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var nameKana = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var gender = ""
    @State private var occupation = ""
    @State private var workplace = ""
    @State private var workplacePhone = ""
    @State private var annualIncome = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    @State private var emergencyContactRelationship = ""
    @State private var moveInDate = Date()
    @State private var hasMoveInDate = false
    @State private var contractEndDate = Date()
    @State private var hasContractEndDate = false
    @State private var rentAmount = ""
    @State private var depositAmount = ""
    @State private var keyMoneyAmount = ""
    @State private var parkingUsed = false
    @State private var parkingSpotNumber = ""
    @State private var licensePlateNumber = ""
    @State private var notes = ""
    @State private var isSaving = false

    var isEdit: Bool { existingTenant != nil }

    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("氏名", text: $name)
                    TextField("フリガナ", text: $nameKana)
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
                    TextField("電話番号", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("メールアドレス", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("職業", text: $occupation)
                    TextField("勤務先", text: $workplace)
                    TextField("勤務先電話", text: $workplacePhone)
                        .keyboardType(.phonePad)
                    TextField("年収（円）", text: $annualIncome)
                        .keyboardType(.numberPad)
                }

                Section("緊急連絡先") {
                    TextField("氏名", text: $emergencyContactName)
                    TextField("続柄（例: 父、配偶者）", text: $emergencyContactRelationship)
                    TextField("電話番号", text: $emergencyContactPhone)
                        .keyboardType(.phonePad)
                }

                Section("契約情報") {
                    Toggle("入居日を設定", isOn: $hasMoveInDate)
                    if hasMoveInDate {
                        DatePicker("入居日", selection: $moveInDate, displayedComponents: .date)
                    }
                    Toggle("契約終了日を設定", isOn: $hasContractEndDate)
                    if hasContractEndDate {
                        DatePicker("契約終了日", selection: $contractEndDate, displayedComponents: .date)
                    }
                    TextField("月額賃料（円）", text: $rentAmount)
                        .keyboardType(.numberPad)
                    TextField("敷金（円）", text: $depositAmount)
                        .keyboardType(.numberPad)
                    TextField("礼金（円）", text: $keyMoneyAmount)
                        .keyboardType(.numberPad)
                }

                Section("駐車場") {
                    Toggle("駐車場を利用する", isOn: $parkingUsed)
                    if parkingUsed {
                        TextField("駐車場番号（例: P-01）", text: $parkingSpotNumber)
                        TextField("ナンバープレート", text: $licensePlateNumber)
                    }
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEdit ? "入居者情報を編集" : "入居者を登録")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { populateIfEditing() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "保存中..." : "保存") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func populateIfEditing() {
        guard let t = existingTenant else { return }
        name = t.name
        nameKana = t.nameKana ?? ""
        email = t.email ?? ""
        phone = t.phone ?? ""
        gender = t.gender ?? ""
        occupation = t.occupation ?? ""
        workplace = t.workplace ?? ""
        workplacePhone = t.workplacePhone ?? ""
        annualIncome = t.annualIncome.map { "\(Int($0))" } ?? ""
        emergencyContactName = t.emergencyContactName ?? ""
        emergencyContactPhone = t.emergencyContactPhone ?? ""
        emergencyContactRelationship = t.emergencyContactRelationship ?? ""
        rentAmount = t.rentAmount.map { "\(Int($0))" } ?? ""
        depositAmount = t.depositAmount.map { "\(Int($0))" } ?? ""
        keyMoneyAmount = t.keyMoneyAmount.map { "\(Int($0))" } ?? ""
        parkingUsed = t.parkingUsed
        parkingSpotNumber = t.parkingSpotNumber ?? ""
        licensePlateNumber = t.licensePlateNumber ?? ""
        notes = t.notes ?? ""

        let df = ISO8601DateFormatter()
        if let bd = t.birthDate, let date = df.date(from: bd) {
            birthDate = date; hasBirthDate = true
        }
        if let mid = t.moveInDate, let date = df.date(from: mid) {
            moveInDate = date; hasMoveInDate = true
        }
        if let ced = t.contractEndDate, let date = df.date(from: ced) {
            contractEndDate = date; hasContractEndDate = true
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let df = ISO8601DateFormatter()
        var data: [String: Any] = [
            "name": name,
            "nameKana": nameKana,
            "email": email,
            "phone": phone,
            "gender": gender,
            "occupation": occupation,
            "workplace": workplace,
            "workplacePhone": workplacePhone,
            "emergencyContactName": emergencyContactName,
            "emergencyContactPhone": emergencyContactPhone,
            "emergencyContactRelationship": emergencyContactRelationship,
            "parkingUsed": parkingUsed,
            "parkingSpotNumber": parkingUsed ? parkingSpotNumber : "",
            "licensePlateNumber": parkingUsed ? licensePlateNumber : "",
            "notes": notes,
        ]
        if hasBirthDate { data["birthDate"] = df.string(from: birthDate) }
        if hasMoveInDate { data["moveInDate"] = df.string(from: moveInDate) }
        if hasContractEndDate { data["contractEndDate"] = df.string(from: contractEndDate) }
        if let ai = Double(annualIncome) { data["annualIncome"] = ai }
        if let ra = Double(rentAmount) { data["rentAmount"] = ra }
        if let da = Double(depositAmount) { data["depositAmount"] = da }
        if let ka = Double(keyMoneyAmount) { data["keyMoneyAmount"] = ka }

        do {
            if isEdit, let id = existingTenant?.id {
                _ = try await TenantService.shared.updateTenant(id: id, data: data)
            } else {
                _ = try await TenantService.shared.createTenant(roomId: roomId, data: data)
            }
            onSaved()
            dismiss()
        } catch {
            print("Save tenant error: \(error)")
        }
    }
}
