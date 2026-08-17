import XCTest
@testable import Arvana_Terra_iOS

// MARK: - Model Tests
final class ModelTests: XCTestCase {

    // MARK: - Property Model Tests
    func testPropertyDecoding() throws {
        let json = """
        {
            "id": "prop-001",
            "name": "サンプルマンション",
            "address": "東京都渋谷区1-2-3",
            "buildingType": "apartment",
            "floors": 10,
            "totalRooms": 40,
            "area": 2500.0,
            "status": "owned",
            "isPublic": true,
            "thumbnailUrl": null,
            "imageUrls": [],
            "purchasePrice": 500000000,
            "currentValue": 520000000,
            "notes": null,
            "ownerId": "user-001",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let property = try decoder.decode(Property.self, from: json)

        XCTAssertEqual(property.id, "prop-001")
        XCTAssertEqual(property.name, "サンプルマンション")
        XCTAssertEqual(property.address, "東京都渋谷区1-2-3")
        XCTAssertEqual(property.buildingType, "apartment")
        XCTAssertEqual(property.floors, 10)
        XCTAssertEqual(property.totalRooms, 40)
        XCTAssertEqual(property.area, 2500.0)
        XCTAssertEqual(property.status, "owned")
        XCTAssertTrue(property.isPublic)
        XCTAssertNil(property.thumbnailUrl)
        XCTAssertEqual(property.purchasePrice, 500000000)
        XCTAssertEqual(property.currentValue, 520000000)
    }

    // MARK: - Land Model Tests
    func testLandDecoding() throws {
        let json = """
        {
            "id": "land-001",
            "name": "テスト土地",
            "address": "大阪府大阪市1-2-3",
            "area": 1000.0,
            "zoning": "第一種住居地域",
            "status": "owned",
            "isPublic": false,
            "thumbnailUrl": null,
            "imageUrls": [],
            "purchasePrice": 200000000,
            "currentValue": 210000000,
            "notes": "日当たり良好",
            "ownerId": "user-001",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let land = try decoder.decode(Land.self, from: json)

        XCTAssertEqual(land.id, "land-001")
        XCTAssertEqual(land.name, "テスト土地")
        XCTAssertEqual(land.area, 1000.0)
        XCTAssertEqual(land.zoning, "第一種住居地域")
        XCTAssertFalse(land.isPublic)
        XCTAssertEqual(land.notes, "日当たり良好")
    }

    // MARK: - Room Model Tests
    func testRoomDecoding() throws {
        let json = """
        {
            "id": "room-001",
            "propertyId": "prop-001",
            "roomNumber": "101",
            "floor": 1,
            "area": 55.5,
            "roomType": "residence",
            "status": "occupied",
            "rentPrice": 150000,
            "occupantName": "田中太郎",
            "occupantContact": "090-1234-5678",
            "contractStartDate": "2024-01-01T00:00:00.000Z",
            "contractEndDate": "2025-01-01T00:00:00.000Z",
            "notes": null,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let room = try decoder.decode(Room.self, from: json)

        XCTAssertEqual(room.id, "room-001")
        XCTAssertEqual(room.roomNumber, "101")
        XCTAssertEqual(room.floor, 1)
        XCTAssertEqual(room.area, 55.5)
        XCTAssertEqual(room.status, "occupied")
        XCTAssertEqual(room.rentPrice, 150000)
        XCTAssertEqual(room.occupantName, "田中太郎")
    }

    // MARK: - ChatMessage Model Tests
    func testChatMessageDecoding() throws {
        let json = """
        {
            "id": "msg-001",
            "chatRoomId": "room-001",
            "senderId": "user-001",
            "senderName": "山田花子",
            "content": "こんにちは",
            "messageType": "text",
            "fileUrl": null,
            "isRead": false,
            "createdAt": "2024-01-01T12:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let message = try decoder.decode(ChatMessage.self, from: json)

        XCTAssertEqual(message.id, "msg-001")
        XCTAssertEqual(message.senderId, "user-001")
        XCTAssertEqual(message.senderName, "山田花子")
        XCTAssertEqual(message.content, "こんにちは")
        XCTAssertEqual(message.messageType, "text")
        XCTAssertFalse(message.isRead)
    }

    // MARK: - Task Model Tests
    func testTaskDecoding() throws {
        let json = """
        {
            "id": "task-001",
            "title": "エアコン点検",
            "description": "全室のエアコンを点検する",
            "propertyId": "prop-001",
            "landId": null,
            "assigneeId": "emp-001",
            "assigneeName": "佐藤次郎",
            "priority": "high",
            "status": "pending",
            "dueDate": "2024-03-31T00:00:00.000Z",
            "completedAt": null,
            "category": "maintenance",
            "notes": null,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let task = try decoder.decode(Task.self, from: json)

        XCTAssertEqual(task.id, "task-001")
        XCTAssertEqual(task.title, "エアコン点検")
        XCTAssertEqual(task.priority, "high")
        XCTAssertEqual(task.status, "pending")
        XCTAssertEqual(task.assigneeName, "佐藤次郎")
    }

    // MARK: - Contract Model Tests
    func testContractDecoding() throws {
        let json = """
        {
            "id": "contract-001",
            "propertyId": "prop-001",
            "landId": null,
            "roomId": "room-001",
            "contractType": "lease",
            "tenantName": "鈴木一郎",
            "tenantContact": "090-9876-5432",
            "tenantEmail": "suzuki@example.com",
            "startDate": "2024-01-01T00:00:00.000Z",
            "endDate": "2025-01-01T00:00:00.000Z",
            "rentAmount": 120000,
            "depositAmount": 240000,
            "status": "active",
            "documentUrl": null,
            "notes": null,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let contract = try decoder.decode(Contract.self, from: json)

        XCTAssertEqual(contract.id, "contract-001")
        XCTAssertEqual(contract.tenantName, "鈴木一郎")
        XCTAssertEqual(contract.contractType, "lease")
        XCTAssertEqual(contract.status, "active")
        XCTAssertEqual(contract.rentAmount, 120000)
        XCTAssertEqual(contract.depositAmount, 240000)
    }

    // MARK: - SnsPost Model Tests
    func testSnsPostDecoding() throws {
        let json = """
        {
            "id": "post-001",
            "authorId": "user-001",
            "authorName": "投稿者A",
            "authorAvatarUrl": null,
            "content": "不動産投資のコツを共有します",
            "category": "knowledge",
            "imageUrls": [],
            "tags": ["不動産", "投資", "節税"],
            "likeCount": 15,
            "commentCount": 3,
            "isLikedByMe": false,
            "isPublic": true,
            "createdAt": "2024-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let post = try decoder.decode(SnsPost.self, from: json)

        XCTAssertEqual(post.id, "post-001")
        XCTAssertEqual(post.authorName, "投稿者A")
        XCTAssertEqual(post.category, "knowledge")
        XCTAssertEqual(post.likeCount, 15)
        XCTAssertEqual(post.tags.count, 3)
        XCTAssertTrue(post.isPublic)
    }

    // MARK: - Equipment Model Tests
    func testEquipmentDecoding() throws {
        let json = """
        {
            "id": "equip-001",
            "propertyId": "prop-001",
            "roomId": null,
            "name": "エレベーター",
            "category": "elevator",
            "manufacturer": "三菱電機",
            "model": "型番XYZ",
            "serialNumber": "SN-12345",
            "installationDate": "2020-01-01T00:00:00.000Z",
            "warrantyExpiry": "2025-01-01T00:00:00.000Z",
            "status": "active",
            "lastMaintenanceDate": "2024-01-01T00:00:00.000Z",
            "nextMaintenanceDate": "2024-07-01T00:00:00.000Z",
            "notes": "年2回点検必須",
            "createdAt": "2020-01-01T00:00:00.000Z",
            "updatedAt": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let equipment = try decoder.decode(Equipment.self, from: json)

        XCTAssertEqual(equipment.id, "equip-001")
        XCTAssertEqual(equipment.name, "エレベーター")
        XCTAssertEqual(equipment.category, "elevator")
        XCTAssertEqual(equipment.manufacturer, "三菱電機")
        XCTAssertEqual(equipment.status, "active")
    }
}

// MARK: - ViewModel Tests
final class ViewModelTests: XCTestCase {

    // MARK: - TaskViewModel Tests
    @MainActor
    func testTaskViewModelPriority() {
        let vm = TaskViewModel()
        XCTAssertEqual(vm.priorityLabel("high"), "高")
        XCTAssertEqual(vm.priorityLabel("medium"), "中")
        XCTAssertEqual(vm.priorityLabel("low"), "低")
    }

    @MainActor
    func testTaskViewModelStatus() {
        let vm = TaskViewModel()
        XCTAssertEqual(vm.statusLabel("pending"), "未着手")
        XCTAssertEqual(vm.statusLabel("in_progress"), "進行中")
        XCTAssertEqual(vm.statusLabel("completed"), "完了")
        XCTAssertEqual(vm.statusLabel("cancelled"), "キャンセル")
    }

    // MARK: - ContractViewModel Tests
    @MainActor
    func testContractViewModelStatus() {
        let vm = ContractViewModel()
        XCTAssertEqual(vm.statusLabel("active"), "有効")
        XCTAssertEqual(vm.statusLabel("expired"), "期限切れ")
        XCTAssertEqual(vm.statusLabel("terminated"), "解除")
        XCTAssertEqual(vm.statusLabel("pending"), "保留中")
    }

    // MARK: - VendorViewModel Tests
    @MainActor
    func testVendorViewModelCategory() {
        let vm = VendorViewModel()
        XCTAssertEqual(vm.categoryLabel("construction"), "建設・工事")
        XCTAssertEqual(vm.categoryLabel("electrical"), "電気工事")
        XCTAssertEqual(vm.categoryLabel("cleaning"), "清掃")
        XCTAssertEqual(vm.categoryLabel("security"), "セキュリティ")
    }

    // MARK: - OpportunityViewModel Tests
    @MainActor
    func testOpportunityViewModelRisk() {
        let vm = OpportunityViewModel()
        XCTAssertEqual(vm.riskLabel("low"), "低リスク")
        XCTAssertEqual(vm.riskLabel("medium"), "中リスク")
        XCTAssertEqual(vm.riskLabel("high"), "高リスク")
    }

    @MainActor
    func testOpportunityViewModelCurrency() {
        let vm = OpportunityViewModel()
        XCTAssertEqual(vm.formatCurrency(nil), "未定")
        XCTAssertEqual(vm.formatCurrency(0), "¥0")
    }

    // MARK: - ValuationViewModel Tests
    @MainActor
    func testValuationViewModelConfidence() {
        let vm = ValuationViewModel()
        XCTAssertEqual(vm.confidenceLabel("high"), "高精度")
        XCTAssertEqual(vm.confidenceLabel("medium"), "中精度")
        XCTAssertEqual(vm.confidenceLabel("low"), "低精度")
    }

    // MARK: - EmployeeViewModel Tests
    @MainActor
    func testEmployeeViewModelType() {
        let vm = EmployeeViewModel()
        XCTAssertEqual(vm.employmentTypeLabel("full_time"), "正社員")
        XCTAssertEqual(vm.employmentTypeLabel("part_time"), "パートタイム")
        XCTAssertEqual(vm.employmentTypeLabel("contract"), "契約社員")
        XCTAssertEqual(vm.employmentTypeLabel("temporary"), "派遣社員")
    }

    // MARK: - SnsViewModel Tests
    @MainActor
    func testSnsViewModelCategory() {
        let vm = SnsViewModel()
        XCTAssertEqual(vm.categoryLabel("general"), "一般")
        XCTAssertEqual(vm.categoryLabel("consultation"), "相談")
        XCTAssertEqual(vm.categoryLabel("knowledge"), "ナレッジ")
        XCTAssertEqual(vm.categoryLabel("case_study"), "事例")
        XCTAssertEqual(vm.categoryLabel("event"), "イベント")
        XCTAssertEqual(vm.categoryLabel("tax"), "税務")
        XCTAssertEqual(vm.categoryLabel("vendor"), "業者")
        XCTAssertEqual(vm.categoryLabel("announcement"), "お知らせ")
    }
}

// MARK: - APIService Tests
final class APIServiceTests: XCTestCase {

    @MainActor
    func testAPIServiceSingleton() {
        let instance1 = APIService.shared
        let instance2 = APIService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    @MainActor
    func testInitialAuthState() {
        // Fresh state (no stored tokens)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "accessToken")
        defaults.removeObject(forKey: "refreshToken")
        XCTAssertFalse(APIService.shared.isAuthenticated)
    }

    @MainActor
    func testSaveAndClearTokens() {
        APIService.shared.saveTokens(accessToken: "test_access", refreshToken: "test_refresh")
        XCTAssertTrue(APIService.shared.isAuthenticated)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "accessToken"), "test_access")

        APIService.shared.clearTokens()
        XCTAssertFalse(APIService.shared.isAuthenticated)
        XCTAssertNil(UserDefaults.standard.string(forKey: "accessToken"))
    }
}

// MARK: - AppConfig Tests
final class AppConfigTests: XCTestCase {

    func testAPIBaseURL() {
        XCTAssertFalse(AppConfig.apiBaseURL.isEmpty)
        XCTAssertTrue(AppConfig.apiBaseURL.hasPrefix("http"))
    }

    func testWebSocketURL() {
        XCTAssertFalse(AppConfig.wsURL.isEmpty)
        XCTAssertTrue(AppConfig.wsURL.hasPrefix("ws"))
    }

    func testAppName() {
        XCTAssertEqual(AppConfig.appName, "Arvana Terra")
    }
}

// MARK: - Color Extension Tests
final class ColorExtensionTests: XCTestCase {

    func testHexColorParsing() {
        // Test that colors are created without crashing
        let navy = Color(hex: "#1B3A6B")
        let blue = Color(hex: "#2E5EAA")
        let accent = Color(hex: "#4A90D9")
        let success = Color(hex: "#059669")
        let warning = Color(hex: "#D97706")
        let error = Color(hex: "#DC2626")

        // Colors should not be nil (they're value types in SwiftUI)
        _ = navy
        _ = blue
        _ = accent
        _ = success
        _ = warning
        _ = error
        XCTAssertTrue(true, "All color initializations successful")
    }

    func testStaticColors() {
        // Test that static color properties exist
        _ = Color.primaryNavy
        _ = Color.secondaryBlue
        _ = Color.accentBlue
        _ = Color.textDark
        _ = Color.textGray
        _ = Color.successGreen
        _ = Color.warningOrange
        _ = Color.errorRed
        _ = Color.backgroundGray
        _ = Color.surfaceWhite
        _ = Color.borderGray
        XCTAssertTrue(true, "All static colors accessible")
    }
}
