# Flutter Flow Graph（フローチャートエディタ）

[![License](https://img.shields.io/badge/license-MulanPSL--2.0-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.16.0-blue.svg)](https://flutter.dev)

> 高性能で外部状態管理に依存しない Flutter ノードグラフエディタパッケージ。
> ドラッグ＆ドロップ接続、ベジェ曲線描画、無限キャンバスのパン／ズームをサポート。
> 7 種類の組み込みノードタイプを備え、ローコードビジュアルオーケストレーション、
> ルールエンジン、ワークフローエディタなどに最適です。

**全プラットフォーム対応：** Android · iOS · Web · Windows · macOS · Linux

 [English](README.md) | [中文（简体）](README.zh-CN.md) | [中文（繁體）](README.zh-TW.md)

## 特徴

- **ノードグラフエディタ** — 無限キャンバス上でドラッグ＆ドロップ、接続
- **7 種類の組み込みノード** — トリガー、読み取り、カウンター、判定、計算、複合判定、実行
- **ベジェ曲線接続** — ポートセマンティクスによる色分け
- **無限キャンバス** — パン、ズーム、グリッド背景、原点マーカー
- **単一ノードテスト** — 各ノードを独立して評価
- **動的入力ポート** — 計算／判定／複合判定／実行ノードで自動追加／削除
- **スナップショットシリアル化** — JSON による完全なエクスポート／インポート
- **ゼロ外部状態管理** — 純粋な `ChangeNotifier`、サードパーティ依存なし
- **多言語対応** — zh_TW（デフォルト）、zh_CN、en、ja
- **プロバイダインターフェース** — `GlobalValueProvider` と `DeviceValueProvider` でカスタムバックエンド

## クイックスタート

```yaml
# pubspec.yaml
dependencies:
 flutter_flow_graph: ^1.0.0
```

```dart
import 'package:flutter_flow_graph/flutter_flow_graph.dart';

// コントローラーを作成
final controller = FlowController();

// レイアウト：左パネル + キャンバス
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

## カスタマイズ

### カスタムバックエンド

```dart
final controller = FlowController(
 globalValues: MyGlobalValueProvider(),
 deviceProvider: MyDeviceValueProvider(),
);
```

### カスタム設定ダイアログ

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

## ノードタイプ

| タイプ | 説明 | 色 |
|------|------|------|
| トリガー | フロー開始：トリガー条件を設定 | ティール |
| 読み取り | デバイスパラメータ／定数／変数を読み取り | 緑 |
| カウンター | キャンバス実行回数をカウント | オレンジ |
| 判定 | 数値を比較判定 | 青 |
| 計算 | 数式で結果を計算 | 紫 |
| 複合判定 | 複数の判定を組み合わせ | ピンク |
| 実行 | アクションを実行 | 赤 |

## ライセンス

Mulan Permissive Software License, Version 2 (MulanPSL-2.0)
