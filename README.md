# Arvana Terra iOS

不動産資産管理プラットフォーム「Arvana Terra」のiOSアプリケーションです。

---

## アプリ概要

Arvana Terra iOSは、不動産オーナー・管理者向けの資産管理アプリです。物件・土地の管理、入居者・契約管理、設備管理、従業員・業者管理、リアルタイムチャット、SNSネットワーク、AIタスク提案、資産評価シミュレーションなど、不動産ビジネスに必要なすべての機能をスマートフォンから直感的に利用できます。

---

## 技術スタック

| 技術 | バージョン |
|------|-----------|
| 言語 | Swift 5.9 |
| UIフレームワーク | SwiftUI (iOS 17.0+) |
| HTTP通信 | URLSession + async/await |
| WebSocket | URLSessionWebSocketTask (Socket.IO EIO4互換) |
| リアクティブ | Combine framework |
| データ永続化 | UserDefaults (トークン管理) |
| グラフ | Swift Charts (iOS 16+) |
| テスト | XCTest |
| 開発ツール | Xcode 15.0+ |

---

## アーキテクチャ: MVVM

```
Views → ViewModels → Services (APIService, SocketService)
```

- **Views**: SwiftUI Viewsで宣言的UI構築
- **ViewModels**: `@MainActor`で安全なUIスレッド更新、`@Published`でリアクティブなデータバインディング
- **Services**: シングルトンパターン (`APIService.shared`, `SocketService.shared`)
- **Models**: `Codable`プロトコルでJSONシリアライズ

---

## 画面一覧

### 認証
- **LoginView** - ログイン画面 (メール・パスワード認証)
- **RegisterView** - 新規アカウント登録

### メインタブ
- **DashboardView** - ホーム・サマリーダッシュボード
  - 物件数、土地数、契約数、タスク数サマリー
  - 未完了タスク一覧
  - 期限が近い契約アラート

### 物件・土地 タブ
- **PublicPropertyListView** - 公開物件一覧
- **PublicPropertyDetailView** - 公開物件詳細
- **PublicLandListView** - 公開土地一覧
- **PublicLandDetailView** - 公開土地詳細
- **MyPropertyListView** - マイ物件一覧
- **MyPropertyDetailView** - マイ物件詳細
- **PropertyManageView** - 物件管理 (部屋・設備・タスク)
- **PropertyChatListView** - 物件チャット一覧
- **PropertyChatRoomView** / **ChatRoomView** - リアルタイムチャット
- **MyLandListView** - マイ土地一覧
- **MyLandDetailView** - マイ土地詳細
- **LandManageView** - 土地管理
- **LandChatListView** - 土地チャット一覧

### 設備管理
- **EquipmentManageView** - 設備一覧・管理
- **EquipmentDetailView** - 設備詳細・メンテナンス記録
- **FloorDetailView** - 階別設備一覧
- **RoomEquipmentDetailView** - 部屋別設備

### 部屋管理
- **RoomListView** - 部屋一覧 (階フィルター)
- **RoomDetailView** - 部屋詳細
- **RoomOccupancyView** - 入居状況グリッドビュー

### 契約管理
- **ContractListView** - 契約一覧 (ステータスフィルター)
- **ContractDetailView** - 契約詳細・解除

### タスク管理
- **TaskManageView** - タスク一覧 (未着手/進行中/完了)
- **AISuggestView** - AIタスク提案

### 従業員・業者
- **EmployeeListView** - 従業員一覧
- **EmployeeDetailView** - 従業員詳細
- **EmployeeChatView** - 従業員とのチャット
- **VendorListView** - 業者一覧 (カテゴリフィルター)
- **VendorDetailView** - 業者詳細

### ネットワーク (SNS) タブ
- **SnsTimelineView** - タイムライン・カテゴリフィルター
- **SnsPostDetailView** - 投稿詳細・コメント
- **ConsultationView** - 相談
- **KnowledgeView** - ナレッジ
- **CaseStudiesView** - 事例
- **EventsView** - イベント
- **TaxAdvisorView** - 税務相談
- **VendorSnsView** - 業者情報
- **AnnouncementsView** - お知らせ

### 分析・評価
- **VisualizationView** - ポートフォリオ分析・グラフ
- **OpportunitiesView** - ビジネス機会一覧
- **ValuationView** - 資産評価履歴・シミュレーション

### 設定タブ
- **SettingsView** - プロフィール・各種管理へのナビゲーション・ログアウト

---

## セットアップ・起動方法

### 前提条件

- macOS 14.0 (Sonoma) 以上
- Xcode 15.0 以上
- iOS 17.0以上のiPhone/iPad、またはシミュレーター

### 手順

**1. プロジェクトを開く**

```bash
open /path/to/Arvana-Terra-iOS/Arvana-Terra-iOS.xcodeproj
```

**2. バックエンドURLの設定**

`Arvana-Terra-iOS/Config/AppConfig.swift` を編集：

```swift
struct AppConfig {
    static let apiBaseURL = "http://YOUR_BACKEND_HOST:3000/api/v1"
    static let wsURL = "ws://YOUR_BACKEND_HOST:3000"
}
```

ローカル開発の場合は `localhost` のままで動作します。

**3. ビルド・実行**

- Xcodeでターゲットデバイス (シミュレーターまたは実機) を選択
- `Cmd + R` でビルド・実行

**4. テストの実行**

```bash
# Xcodeで
Cmd + U
```

---

## バックエンド API 接続設定

### 認証フロー

```
POST /api/v1/auth/login       → JWT accessToken + refreshToken
POST /api/v1/auth/register    → 新規登録
POST /api/v1/auth/refresh     → トークンリフレッシュ (401時自動実行)
POST /api/v1/auth/logout      → ログアウト
GET  /api/v1/auth/me          → 現在のユーザー情報
```

### 主要エンドポイント

```
# 物件
GET    /api/v1/properties/public  → 公開物件一覧
GET    /api/v1/properties/my      → マイ物件一覧
GET    /api/v1/properties/:id     → 物件詳細
POST   /api/v1/properties         → 物件作成
PUT    /api/v1/properties/:id     → 物件更新
DELETE /api/v1/properties/:id     → 物件削除

# 土地
GET    /api/v1/lands/public       → 公開土地一覧
GET    /api/v1/lands/my           → マイ土地一覧

# チャット
GET    /api/v1/chat/rooms              → チャットルーム一覧
GET    /api/v1/chat/rooms/:id/messages → メッセージ一覧
POST   /api/v1/chat/rooms/:id/messages → メッセージ送信

# その他
GET  /api/v1/contracts       → 契約一覧
GET  /api/v1/tasks           → タスク一覧
POST /api/v1/tasks/ai-suggest → AIタスク提案
GET  /api/v1/valuations/calculate → 評価額計算
```

### WebSocket 接続 (Socket.IO EIO4)

```
ws://HOST:3000/socket.io/?EIO=4&transport=websocket&token=JWT_TOKEN
```

| イベント | 方向 | 説明 |
|---------|------|------|
| join_room | 送信 | チャットルーム入室 |
| leave_room | 送信 | チャットルーム退室 |
| send_message | 送信 | メッセージ送信 |
| new_message | 受信 | 新しいメッセージ受信 |
| typing | 送受信 | 入力中通知 |
| stop_typing | 送受信 | 入力終了通知 |

### App Transport Security (ATS)

ローカル開発時 (`http://localhost`) のためATSを緩和しています。
本番環境ではHTTPSを使用し、ATS設定を適切に制限してください。

---

## プロジェクト構造

```
Arvana-Terra-iOS/
├── Arvana-Terra-iOS/
│   ├── ArvanaTerraiOSApp.swift   # @main エントリポイント
│   ├── ContentView.swift          # 認証ルーティング
│   ├── Config/
│   │   └── AppConfig.swift        # API URL・カラー拡張
│   ├── Services/
│   │   ├── APIService.swift       # REST APIクライアント (singleton)
│   │   └── SocketService.swift    # WebSocketクライアント (singleton)
│   ├── Models/                    # Codable データモデル
│   │   ├── User.swift
│   │   ├── Property.swift
│   │   ├── Land.swift
│   │   ├── Room.swift
│   │   ├── Equipment.swift
│   │   ├── Contract.swift
│   │   ├── ChatRoom.swift
│   │   ├── Task.swift
│   │   ├── Employee.swift
│   │   ├── Vendor.swift
│   │   ├── SnsPost.swift
│   │   ├── BusinessOpportunity.swift
│   │   ├── AssetValuation.swift
│   │   └── Notification.swift
│   ├── ViewModels/                # @MainActor ObservableObject
│   │   ├── AuthViewModel.swift
│   │   ├── PropertyViewModel.swift
│   │   ├── LandViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   ├── EquipmentViewModel.swift
│   │   ├── ContractViewModel.swift
│   │   ├── TaskViewModel.swift
│   │   ├── EmployeeViewModel.swift
│   │   ├── VendorViewModel.swift
│   │   ├── SnsViewModel.swift
│   │   ├── OpportunityViewModel.swift
│   │   └── ValuationViewModel.swift
│   └── Views/                     # SwiftUI Views
│       ├── Auth/
│       ├── Dashboard/
│       ├── Public/
│       ├── MyProperties/
│       ├── MyLands/
│       ├── Equipment/
│       ├── Contracts/
│       ├── Tasks/
│       ├── Rooms/
│       ├── Employees/
│       ├── Vendors/
│       ├── Visualization/
│       ├── Opportunities/
│       ├── Valuation/
│       ├── SNS/
│       ├── Settings/
│       └── Components/
├── Arvana-Terra-iOS.xcodeproj/
│   └── project.pbxproj
├── Arvana-Terra-iOSTests/
│   └── Arvana_Terra_iOSTests.swift
└── README.md
```

---

## デザインシステム

| カラー | HEX | 用途 |
|--------|-----|------|
| Primary Navy | `#1B3A6B` | メインブランドカラー |
| Secondary Blue | `#2E5EAA` | サブカラー |
| Accent Blue | `#4A90D9` | アクセント |
| Text Dark | `#1A1A2E` | 本文テキスト |
| Text Gray | `#6B7280` | サブテキスト |
| Success | `#059669` | 成功・有効状態 |
| Warning | `#D97706` | 警告・注意 |
| Error | `#DC2626` | エラー・危険 |
| Background | `#FAFAFA` | 画面背景 |
| Surface | `#FFFFFF` | カード背景 |

---

## ライセンス

Copyright (c) 2024 Arvana Terra. All rights reserved.
