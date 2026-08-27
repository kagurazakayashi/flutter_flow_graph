# Flutter Flow Graph（Flutter 流程圖編輯器）

[![License](https://img.shields.io/badge/license-MulanPSL--2.0-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.16.0-blue.svg)](https://flutter.dev)

> 一個高效能、零外部狀態管理依賴的 Flutter 節點圖編輯器套件。
> 支援拖放連線、貝塞爾曲線繪製、無限畫布平移縮放，
> 內建七種節點型別（觸發、讀取、計數器、判斷、運算、組合判斷、執行），
> 適用於低程式碼視覺化編排、規則引擎、工作流程編輯器等場景。

**全平台支援：** Android · iOS · Web · Windows · macOS · Linux

📖 [English](README.md) | [中文（简体）](README.zh-CN.md) | [日本語](README.ja-JP.md)

## 特性

- 🎨 **節點圖編輯器** — 在無限畫布上拖放、連線節點
- 🧩 **7 種內建節點型別** — 觸發、讀取、計數器、判斷、運算、組合判斷、執行
- 🔗 **貝塞爾曲線連線** — 依埠語義著色（true 綠、false 紅、其餘灰藍）
- 🔍 **無限畫布** — 平移、縮放、網格背景與原點標記
- 🧪 **單節點測試** — 獨立評估每個節點
- 🔄 **動態輸入埠** — 運算／判斷／組合判斷／執行節點可自動增減輸入埠
- 💾 **快照序列化** — 完整的 JSON 匯出／匯入畫布狀態
- 🎯 **零外部狀態管理** — 純 `ChangeNotifier`，無第三方依賴
- 🌐 **多語言** — zh_TW（預設）、zh_CN、en、ja
- 🔌 **提供者介面模式** — 透過 `GlobalValueProvider` 和 `DeviceValueProvider` 自訂後端

## 快速開始

```yaml
# pubspec.yaml
dependencies:
  flutter_flow_graph: ^1.0.0
```

```dart
import 'package:flutter_flow_graph/flutter_flow_graph.dart';

// 建立控制器
final controller = FlowController();

// 佈局：左側面板 + 畫布
Row(
  children: [
    BlockPalette(
      onAddBlock: (type) => controller.addNode(type, Offset(0, 0)),
    ),
    Expanded(
      child: NodeCanvas(controller: controller),
    ),
  ],
)
```

## 自訂

### 自訂後端提供者

```dart
final controller = FlowController(
  globalValues: MyGlobalValueProvider(),
  deviceProvider: MyDeviceValueProvider(),
);
```

### 自訂節點設定對話框

```dart
NodeCanvas(
  controller: controller,
  onNodeConfigRequested: (context, nodeId) {
    showDialog(
      context: context,
      builder: (_) => MyCustomConfigDialog(
        nodeId: nodeId,
        controller: controller,
      ),
    );
  },
)
```

### 自訂面板節點

```dart
BlockPalette(
  onAddBlock: (type) => controller.addNode(type, Offset(0, 0)),
  customBlockTypes: [
    CustomPaletteBlockType(
      label: 'HTTP 請求',
      description: '發送 HTTP API 請求',
      color: Colors.blue,
      onTap: () {
        // 自訂邏輯
      },
    ),
  ],
)
```

## 節點型別

| 型別 | 說明 | 顏色 |
|------|------|------|
| 觸發 | 流程起點：設定觸發條件 | 墨綠 |
| 讀取 | 讀取裝置參數／常數／變數 | 綠色 |
| 計數器 | 計算畫布執行次數 | 橙色 |
| 判斷 | 對數值進行比較判斷 | 藍色 |
| 運算 | 依公式計算結果 | 紫色 |
| 組合判斷 | 組合多個判斷結果 | 粉色 |
| 執行 | 執行動作 | 紅色 |

## 授權

Mulan Permissive Software License，第 2 版（MulanPSL-2.0）
