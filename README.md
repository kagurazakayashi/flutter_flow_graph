# Flutter Flow Graph

[![License](https://img.shields.io/badge/license-MulanPSL--2.0-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.2.0-blue.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.16.0-blue.svg)](https://flutter.dev)

> A high-performance, zero-external-state-management-dependency Flutter
> Node Graph Editor package. Supports drag-and-drop connections,
> Bézier curve rendering, infinite canvas pan/zoom, with seven built-in
> node types suitable for low-code visual orchestration, rule engines,
> workflow editors, and more.

**Supports all platforms:** Android · iOS · Web · Windows · macOS · Linux

📖 [中文（简体）](README.zh-CN.md) | [中文（繁體）](README.zh-TW.md) | [日本語](README.ja-JP.md)

## Features

- 🎨 **Node Graph Editor** — Drag, drop, and connect nodes on an infinite canvas
- 🧩 **7 Built-in Node Types** — Trigger, Read, Counter, Judge, Calc, Composite, Execute
- 🔗 **Bézier Curve Connections** — Color-coded by port semantics
- 🔍 **Infinite Canvas** — Pan, zoom, grid background with origin marker
- 🧪 **Single-node Testing** — Evaluate each node independently
- 🔄 **Dynamic Input Ports** — Auto-add/remove input ports on Calc, Judge, Composite, Execute nodes
- 💾 **Snapshot Serialization** — Full JSON export/import of canvas state
- 🎯 **Zero External State Management** — Pure `ChangeNotifier`, no third-party dependencies
- 🌐 **Multi-language** — zh_TW (default), zh_CN, en, ja
- 🔌 **Provider Interface Pattern** — Custom backend via `GlobalValueProvider` and `DeviceValueProvider`

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  flutter_flow_graph: ^1.0.0
```

```dart
import 'package:flutter_flow_graph/flutter_flow_graph.dart';

class MyFlowEditor extends StatefulWidget {
  @override
  State<MyFlowEditor> createState() => _MyFlowEditorState();
}

class _MyFlowEditorState extends State<MyFlowEditor> {
  final controller = FlowController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel: block palette
        BlockPalette(
          onAddBlock: (type) {
            controller.addNode(type, Offset(0, 0));
          },
          fontScale: controller.fontScale,
        ),
        // Main canvas
        Expanded(
          child: NodeCanvas(
            controller: controller,
            onExitTextInput: () => FocusScope.of(context).unfocus(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Customization

### Custom Backend Providers

```dart
final controller = FlowController(
  globalValues: MyGlobalValueProvider(),
  deviceProvider: MyDeviceValueProvider(),
);
```

### Custom Node Config Dialog

```dart
NodeCanvas(
  controller: controller,
  onNodeConfigRequested: (context, nodeId) {
    // Show your custom dialog
    showDialog(
      context: context,
      builder: (_) => MyCustomConfigDialog(nodeId: nodeId, controller: controller),
    );
  },
)
```

### Custom Palette Blocks

```dart
BlockPalette(
  onAddBlock: (type) => controller.addNode(type, Offset(0, 0)),
  customBlockTypes: [
    CustomPaletteBlockType(
      label: 'HTTP Request',
      description: 'Make HTTP API calls',
      color: Colors.blue,
      onTap: () {
        // Your custom logic
      },
    ),
  ],
)
```

## Node Types

| Type | Description | Color |
|------|-------------|-------|
| Trigger | Flow start: set trigger condition | Teal |
| Read | Read device param / constant / variable | Green |
| Counter | Count canvas execution cycles | Orange |
| Judge | Compare numeric values | Blue |
| Calc | Compute result by formula | Purple |
| Composite | AND / OR / NOT combine conditions | Pink |
| Execute | Send email / HTTP request | Red |

## License

Mulan Permissive Software License, Version 2 (MulanPSL-2.0)
