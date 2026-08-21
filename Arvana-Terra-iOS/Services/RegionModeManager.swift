import Foundation
import Combine

class RegionModeManager: ObservableObject {
    static let shared = RegionModeManager()

    @Published var displayMode: DisplayMode {
        didSet { UserDefaults.standard.set(displayMode.rawValue, forKey: "displayMode") }
    }
    @Published var displayPrefectures: [String] {
        didSet { UserDefaults.standard.set(displayPrefectures, forKey: "displayPrefectures") }
    }

    enum DisplayMode: String, CaseIterable {
        case nationwide = "nationwide"
        case regional = "regional"

        var label: String {
            switch self {
            case .nationwide: return "全国"
            case .regional: return "地域"
            }
        }

        var icon: String {
            switch self {
            case .nationwide: return "globe.asia.australia"
            case .regional: return "map.fill"
            }
        }
    }

    private init() {
        let savedMode = UserDefaults.standard.string(forKey: "displayMode") ?? "nationwide"
        self.displayMode = DisplayMode(rawValue: savedMode) ?? .nationwide
        self.displayPrefectures = UserDefaults.standard.stringArray(forKey: "displayPrefectures") ?? []
    }

    func toggleMode() {
        displayMode = displayMode == .nationwide ? .regional : .nationwide
    }

    var isRegionalMode: Bool { displayMode == .regional }

    // APIコール時の都道府県フィルター（地域モード時のみ）
    var prefectureFilter: String? {
        guard isRegionalMode, !displayPrefectures.isEmpty else { return nil }
        return displayPrefectures.first
    }
}
