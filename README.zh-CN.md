# Flutter Flow Graph

[![License](https://img.shields.io/badge/license-MulanPSL--2.0-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.16.0-blue.svg)](https://flutter.dev)

> 一个高性能、零外部状态管理依赖的 Flutter 节点图编辑器套件。
> 支持拖放连线、贝塞尔曲线绘制、无限画布平移缩放，
> 内置七种节点类型（触发、读取、计数器、判断、运算、组合判断、执行），
> 适用于低代码可视化编排、规则引擎、工作流编辑器等场景。

**全平台支持：** Android · iOS · Web · Windows · macOS · Linux

📖 [English](README.md) | [中文（繁體）](README.zh-TW.md) | [日本語](README.ja-JP.md)

## 特性

- 🎨 **节点图编辑器** — 在无限画布上拖放、连接节点
- 🧩 **7 种内置节点类型** — 触发、读取、计数器、判断、运算、组合判断、执行
- 🔗 **贝塞尔曲线连线** — 按端口语义着色
- 🔍 **无限画布** — 平移、缩放、网格背景与原点标记
- 🧪 **单节点测试** — 独立评估每个节点
- 🔄 **动态输入端口** — 运算/判断/组合判断/执行节点可自动增减输入端口
- 💾 **快照序列化** — 完整的 JSON 导出/导入画布状态
- 🎯 **零外部状态管理** — 纯 `ChangeNotifier`，无第三方依赖
- 🌐 **多语言** — zh_TW（默认）、zh_CN、en、ja
- 🔌 **提供者接口模式** — 通过 `GlobalValueProvider` 和 `DeviceValueProvider` 自定义后端

## 快速开始

```yaml
# pubspec.yaml
dependencies:
  flutter_flow_graph: ^1.0.0
```

```dart
import 'package:flutter_flow_graph/flutter_flow_graph.dart';

// 创建控制器
final controller = FlowController();

// 布局：左侧面板 + 画布
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

## 自定义

### 自定义后端提供者

```dart
final controller = FlowController(
  globalValues: MyGlobalValueProvider(),
  deviceProvider: MyDeviceValueProvider(),
);
```

### 自定义节点配置对话框

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

## 节点类型

| 类型 | 说明 | 颜色 |
|------|------|------|
| 触发 | 流程起点：设置触发条件 | 墨绿 |
| 读取 | 读取设备参数/常量/变量 | 绿色 |
| 计数器 | 计算画布运行次数 | 橙色 |
| 判断 | 对数值进行比较判断 | 蓝色 |
| 运算 | 按公式计算结果 | 紫色 |
| 组合判断 | 组合多个判断结果 | 粉色 |
| 执行 | 执行动作 | 红色 |

## 许可证

木兰宽松许可证，第 2 版（MulanPSL-2.0）
