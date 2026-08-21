import SwiftUI

// MARK: - App Configuration
enum AppConfig {
    static let baseURL = "http://localhost:3000/api"
    static let appName = "ARVANA Terra"

    // MARK: - 都道府県リスト
    static let prefectures = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
        "岐阜県", "静岡県", "愛知県", "三重県",
        "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
        "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県",
        "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
}

// MARK: - Color Extensions
extension Color {
    static let primaryNavy = Color(red: 0.10, green: 0.20, blue: 0.40)
    static let secondaryBlue = Color(red: 0.20, green: 0.40, blue: 0.70)
    static let accentBlue = Color(red: 0.30, green: 0.55, blue: 0.90)
    static let successGreen = Color(red: 0.20, green: 0.65, blue: 0.40)
    static let errorRed = Color(red: 0.80, green: 0.20, blue: 0.20)
    static let warningOrange = Color(red: 0.90, green: 0.55, blue: 0.10)
    static let textDark = Color(red: 0.10, green: 0.10, blue: 0.15)
    static let textGray = Color(red: 0.50, green: 0.50, blue: 0.55)
    static let borderGray = Color(red: 0.80, green: 0.80, blue: 0.83)
    static let backgroundLight = Color(red: 0.96, green: 0.96, blue: 0.97)
}
