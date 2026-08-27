# AGENT.md — Flutter Flow Graph

## 專案概述

`flutter_flow_graph` 是一個高效能、零外部狀態管理依賴的 Flutter 節點圖編輯器套件。
支援拖放連線、貝塞爾曲線繪製、無限畫布平移縮放，
內建七種節點型別（觸發、讀取、計數器、判斷、運算、組合判斷、執行），
適用於低程式碼視覺化編排、規則引擎、工作流程編輯器等場景。

## 技術棧

- **語言**：Dart（zh_TW 繁體中文註解與文件註解）
- **框架**：Flutter >= 3.16.0
- **SDK**：Dart >= 3.2.0
- **狀態管理**：純 `ChangeNotifier`（零外部狀態管理依賴）
- **授權**：MulanPSL-2.0
- **作者**：KagurazakaMiyabi（神楽坂雅詩）

## 目錄結構

```
flutter_flow_graph/
├── lib/
│   ├── flutter_flow_graph.dart          # 套件入口（export 所有公開 API）
│   └── src/
│       ├── models/
│       │   ├── block_config.dart       # 節點設定模型
│       │   ├── block_test.dart         # 測試結果模型
│       │   ├── flow_connection.dart    # 連線模型
│       │   ├── flow_node.dart          # 節點模型（含 BlockType、NodeMetrics、NodePort）
│       │   ├── flow_snapshot.dart      # 畫布快照（序列化）
│       │   └── global_value.dart       # 全域值（常數／變數）
│       ├── controllers/
│       │   ├── flow_controller.dart    # 核心狀態管理（ChangeNotifier）
│       │   └── editor_settings.dart    # 編輯器設定
│       ├── widgets/
│       │   ├── block_palette.dart      # 左側節點面板
│       │   ├── block_test_toast.dart   # 測試結果 Toast
│       │   ├── node_canvas.dart        # 無限畫布（網格、連線、節點容器）
│       │   ├── node_widget.dart        # 單個節點元件
│       │   └── port_widget.dart        # 埠圓點元件
│       └── i18n/
│           ├── l10n/                   # ARB 在地化資源
│           └── gen/                    # gen_l10n 自動產生
├── example/                            # 測試專案
├── test/                               # 單元測試
├── doc/                                # 文件
├── pubspec.yaml
├── l10n.yaml
├── LICENSE
├── CHANGELOG.md
├── AGENT.md
├── README.md
├── README_zh_CN.md
├── README_zh_TW.md
└── README_ja.md
```

## 核心概念

### 節點（FlowNode）

每個節點代表一個處理單元，包含：
- `id`：唯一識別碼
- `type`：節點型別（BlockType 列舉）
- `position`：世界座標位置
- `inputs` / `outputs`：輸入／輸出埠列表
- `config`：型別特定設定（BlockConfig）

### 連線（FlowConnection）

從一個節點的輸出埠連接到另一個節點的輸入埠：
- `fromNodeId` / `fromPortId` → `toNodeId` / `toPortId`

### 畫布（NodeCanvas）

無限畫布，支援：
- 點狀網格背景
- 平移（單指／滑鼠拖曳）
- 縮放（雙指捏合／滑鼠滾輪）
- 拖放節點
- 連線建立／刪除
- 貝塞爾曲線渲染

### 內建節點型別

| 型別 | 說明 | 顏色 |
|------|------|------|
| Trigger | 流程起點：設定觸發條件 | 墨綠 |
| Read | 讀取裝置參數／常數／變數 | 綠色 |
| Counter | 計算畫布執行次數 | 橙色 |
| Judge | 對數值進行比較判斷 | 藍色 |
| Calc | 依公式計算結果 | 紫色 |
| Composite | 組合多個判斷結果 | 粉色 |
| Execute | 執行動作 | 紅色 |

## 關鍵設計決策

1. **零外部狀態管理依賴**：`FlowController` 是純 `ChangeNotifier`，消費方無需引入任何第三方狀態管理庫。
2. **提供者介面模式**：`GlobalValueProvider` 和 `DeviceValueProvider` 是抽象介面，消費方可以自行實作後端接入邏輯。
3. **快照序列化**：`FlowSnapshot` 支援 JSON 序列化，節點和連線可完整匯出／匯入。
4. **動態輸入埠**：運算、判斷、組合判斷、執行節點支援動態增減輸入埠。
5. **顏色語義**：連線顏色依埠語義變化（true 埠綠色、false 埠紅色、其餘灰藍色）。
6. **設定委派**：透過 `onNodeConfigRequested` 回呼，消費方可提供自訂設定對話框。

## 多語言支援

支援四種語言，zh_TW 為預設語言：
- 繁體中文（zh_TW）
- 簡體中文（zh_CN）
- 英文（en）
- 日文（ja）

## 開發指南

### 產生在地化程式碼

```bash
cd flutter_flow_graph
flutter gen-l10n
```

### 執行測試

```bash
flutter test
```

### 執行範例

```bash
cd example
flutter run
```

## 貢獻指南

1. 所有程式碼註解使用繁體中文（zh_TW）
2. 公開 API 需有完整的文件註解（`///`）
3. 狀態變更必須透過 `FlowController` 並呼叫 `notifyListeners()`
4. 新增節點型別需先在 `BlockType` 列舉中註冊
5. 保持零外部狀態管理依賴