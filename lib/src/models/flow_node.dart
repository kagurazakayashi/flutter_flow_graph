import 'dart:ui';

import 'block_config.dart';

// ---------------------------------------------------------------------------
// 節點類型定義（低程式碼視覺化編排畫布中的節點類型）。
// 消費方可透過 [BlockTypeRegistry] 自訂節點類型，或直接使用內建七種類型。
// ---------------------------------------------------------------------------

/// 內建節點類型。
enum BlockType { trigger, read, counter, judge, calc, composite, execute }

/// 自訂節點類型定義。
/// 消費方可實作此介面以註冊自訂節點類型到 [BlockTypeRegistry]。
abstract class CustomBlockType {
  /// 節點類型唯一識別碼（如 'custom-http'）。
  String get id;

  /// 節點類型顯示名稱。
  String get label;

  /// 節點類型顯示顏色。
  Color get color;

  /// 節點類型簡述。
  String get description;
}

/// 節點類型註冊中心。
/// 消費方可透過 [register] 方法註冊自訂節點類型，
/// 並透過 [byId] 等方法查詢。
class BlockTypeRegistry {
  BlockTypeRegistry._();

  static final Map<String, CustomBlockType> _custom = {};

  /// 註冊自訂節點類型。
  static void register(CustomBlockType type) {
    _custom[type.id] = type;
  }

  /// 取消註冊自訂節點類型。
  static void unregister(String id) {
    _custom.remove(id);
  }

  /// 以 ID 查詢自訂節點類型。
  static CustomBlockType? byId(String id) => _custom[id];

  /// 取得所有已註冊的自訂節點類型。
  static List<CustomBlockType> get all => _custom.values.toList();
}

/// 內建節點類型的顯示名稱（由應用層在地化後傳入）。
String builtinBlockTypeLabel(BlockType type) => switch (type) {
  BlockType.trigger => '觸發',
  BlockType.read => '讀取',
  BlockType.counter => '計數器',
  BlockType.judge => '判斷',
  BlockType.calc => '運算',
  BlockType.composite => '組合判斷',
  BlockType.execute => '執行',
};

/// 內建節點類型的顯示顏色。
Color builtinBlockTypeColor(BlockType type) => switch (type) {
  BlockType.trigger => const Color(0xFF00897B),
  BlockType.read => const Color(0xFF4CAF50),
  BlockType.counter => const Color(0xFFFF9800),
  BlockType.judge => const Color(0xFF2196F3),
  BlockType.calc => const Color(0xFF9C27B0),
  BlockType.composite => const Color(0xFFE91E63),
  BlockType.execute => const Color(0xFFF44336),
};

/// 內建節點類型的簡述文字。
String builtinBlockTypeDescription(BlockType type) => switch (type) {
  BlockType.trigger => '流程起點：設定觸發條件',
  BlockType.read => '讀取裝置參數／常數／變數',
  BlockType.counter => '計算畫布執行次數',
  BlockType.judge => '對數值進行比較判斷',
  BlockType.calc => '依公式計算結果',
  BlockType.composite => 'AND / OR / NOT 組合多個判斷',
  BlockType.execute => '執行郵件／HTTP 等動作',
};

// ---------------------------------------------------------------------------
// 節點度量（尺寸相關常數），所有尺寸都隨字型縮放係數 [fs] 自適應。
// ---------------------------------------------------------------------------

/// 節點尺寸（基準尺寸對應 fontScale = 1.0，實際尺寸依字型縮放係數放大，
/// 節點大小隨字型大小自適應）。
class NodeMetrics {
  static const double baseWidth = 200;
  static const double baseHeaderHeight = 48;
  static const double baseConfigHeight = 24;
  static const double baseCurrentHeight = 26;
  static const double baseRowHeight = 28;
  static const double baseCornerRadius = 12;
  static const double basePortRadius = 8;

  /// 埠圓心相對節點邊緣的偏移（使圓點約 2/3 位於節點內）。
  static const double basePortInset = 3;

  static const double baseBottomPadding = 8;

  static double width(double fs) => baseWidth * fs;
  static double headerHeight(double fs) => baseHeaderHeight * fs;
  static double configHeight(double fs) => baseConfigHeight * fs;

  /// 讀取節點「目前值」行的高度（位於設定條與埠區之間）。
  static double currentHeight(double fs) => baseCurrentHeight * fs;

  static double rowHeight(double fs) => baseRowHeight * fs;
  static double cornerRadius(double fs) => baseCornerRadius * fs;
  static double portRadius(double fs) => basePortRadius * fs;
  static double portInset(double fs) => basePortInset * fs;

  /// 節點高度 = 標題區 + 設定條 + max(輸入數, 輸出數) * 行高 + 底部留白。
  static double height(int inputCount, int outputCount, double fs) {
    final rows = inputCount > outputCount ? inputCount : outputCount;
    return headerHeight(fs) +
        configHeight(fs) +
        rows * rowHeight(fs) +
        baseBottomPadding;
  }
}

// ---------------------------------------------------------------------------
// 埠方向與埠定義
// ---------------------------------------------------------------------------

/// 埠方向。
enum PortDirection { input, output }

/// 節點的輸入／輸出埠。
class NodePort {
  const NodePort({
    required this.id,
    required this.label,
    required this.direction,
  });

  final String id;
  final String label;
  final PortDirection direction;
}

// ---------------------------------------------------------------------------
// 動態埠相關常數與工具函式
// ---------------------------------------------------------------------------

/// 動態入口節點類型（入口數不確認）：首個輸入埠恆存在，其餘透過「新增點」連線自動新增。
bool isDynamicInputType(BlockType type) => switch (type) {
  BlockType.calc ||
  BlockType.judge ||
  BlockType.composite ||
  BlockType.execute => true,
  _ => false,
};

/// 動態入口節點的預設首個輸入埠 ID（恆存在，不可刪除）。
/// - 運算：x（預設輸入）；判斷：x（判斷值）；組合判斷：in1；執行：trigger（判斷值）。
String defaultInputPortId(BlockType type) => switch (type) {
  BlockType.calc => 'x',
  BlockType.judge => 'x',
  BlockType.composite => 'in1',
  BlockType.execute => 'trigger',
  _ => '',
};

/// 運算節點額外輸入埠標籤池。
const List<String> calcExtraInputPortIds = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
];

/// 判斷節點額外輸入埠標籤池。
const List<String> judgeExtraInputPortIds = ['a', 'b'];

/// 組合判斷節點額外輸入埠標籤池。
const List<String> compositeExtraInputPortIds = [
  'in2', 'in3', 'in4', 'in5', 'in6', 'in7', 'in8', 'in9', 'in10',
];

/// 執行節點額外輸入埠標籤池。
const List<String> executeExtraInputPortIds = [
  'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9',
];

/// 動態入口節點的額外輸入埠標籤池；非動態類型返回空列表。
List<String> extraInputPortIds(BlockType type) => switch (type) {
  BlockType.calc => calcExtraInputPortIds,
  BlockType.judge => judgeExtraInputPortIds,
  BlockType.composite => compositeExtraInputPortIds,
  BlockType.execute => executeExtraInputPortIds,
  _ => const [],
};

/// 動態入口節點的最大輸入埠數（首個 + 額外標籤池大小）。
int maxDynamicInputs(BlockType type) => 1 + extraInputPortIds(type).length;

/// 「新增點」的偽埠 ID：節點上最後一個可連線點，
/// 連線落在此點會自動新增輸入埠並連上。
const String addPointPortId = '__add_point__';

/// 埠顯示標籤（執行節點 trigger / 次要 與 id 不同）。
String inputPortLabel(BlockType type, String portId) => switch (type) {
  BlockType.execute when portId == 'trigger' => '判斷值',
  BlockType.execute when portId.startsWith('p') => '次要${portId.substring(1)}',
  _ => portId,
};

/// 動態入口節點啟用的額外輸入埠標籤：依標籤池標準順序過濾、去重、排序。
/// 刪除埠後保留空缺標號，再次新增取最小空缺標號，操作完成後統一依標準順序排列
/// （例：x a b c 刪除 a -> x b c，再次新增 -> x a b c）。
List<String> sortedExtraPorts(BlockType type, List<String> labels) {
  final pool = extraInputPortIds(type);
  final seen = <String>{};
  final result = <String>[];
  for (final id in pool) {
    if (labels.contains(id) && seen.add(id)) result.add(id);
  }
  return result;
}

/// 各節點類型的預設輸入埠。
List<NodePort> buildInputPorts(BlockType type, BlockConfig config) {
  switch (type) {
    case BlockType.trigger:
      return const [];
    case BlockType.read:
      return const [
        NodePort(id: 'in', label: '流程', direction: PortDirection.input),
      ];
    case BlockType.counter:
      return const [
        NodePort(id: 'in', label: 'in', direction: PortDirection.input),
      ];
    case BlockType.judge:
    case BlockType.calc:
    case BlockType.composite:
    case BlockType.execute:
      return [
        NodePort(
          id: defaultInputPortId(type),
          label: inputPortLabel(type, defaultInputPortId(type)),
          direction: PortDirection.input,
        ),
        for (final id in sortedExtraPorts(type, config.extraInputPorts))
          NodePort(
            id: id,
            label: inputPortLabel(type, id),
            direction: PortDirection.input,
          ),
      ];
  }
}

/// 各節點類型的預設輸出埠。
List<NodePort> buildOutputPorts(BlockType type, BlockConfig config) {
  switch (type) {
    case BlockType.trigger:
      return const [
        NodePort(id: 'out', label: 'out', direction: PortDirection.output),
      ];
    case BlockType.read:
      return const [
        NodePort(id: 'out', label: 'out', direction: PortDirection.output),
      ];
    case BlockType.counter:
    case BlockType.judge:
    case BlockType.composite:
      return const [
        NodePort(id: 'true', label: 'true', direction: PortDirection.output),
        NodePort(id: 'false', label: 'false', direction: PortDirection.output),
        NodePort(id: 'bool', label: 'bool', direction: PortDirection.output),
      ];
    case BlockType.calc:
      return const [
        NodePort(id: 'out', label: 'out', direction: PortDirection.output),
      ];
    case BlockType.execute:
      return const [];
  }
}

// ---------------------------------------------------------------------------
// FlowNode（流程節點）
// ---------------------------------------------------------------------------

/// 流程節點（視覺化節點）。
class FlowNode {
  FlowNode({
    required this.id,
    required this.type,
    required this.position,
    String? title,
    List<NodePort>? inputs,
    List<NodePort>? outputs,
    BlockConfig? config,
  }) : config = config ?? BlockConfig(),
       title = title ?? builtinBlockTypeLabel(type) {
    final cfg = this.config;
    this.inputs = inputs ?? buildInputPorts(type, cfg);
    this.outputs = outputs ?? buildOutputPorts(type, cfg);
  }

  final String id;
  final BlockType type;
  String title;

  /// 節點在畫布（世界）座標系中的左上角位置。
  Offset position;

  /// 節點型別特有設定（判斷運算子、運算公式、組合邏輯、執行動作等）。
  BlockConfig config;

  /// 輸入／輸出埠（由型別與設定決定，建構時賦值）。
  late List<NodePort> inputs;
  late List<NodePort> outputs;

  /// 節點高度（依字型縮放係數 [fs]）。
  double height(double fs) {
    var rows = inputs.length > outputs.length ? inputs.length : outputs.length;
    // 動態入口節點未展開到上限時，末尾多留一行放置「新增點」（可連線自動新增入口）。
    if (isDynamicInputType(type) && inputs.length < maxDynamicInputs(type)) {
      rows += 1;
    }
    // 除執行節點外都有一行「目前值／目前結果」（設定條與埠區之間）。
    final current = type == BlockType.execute
        ? 0.0
        : NodeMetrics.currentHeight(fs);
    return NodeMetrics.height(rows, 0, fs) + current;
  }

  /// 更新設定並重建埠（同時供控制器清理失效連線）。
  void updateConfig(BlockConfig newConfig) {
    config = newConfig;
    inputs = buildInputPorts(type, newConfig);
    outputs = buildOutputPorts(type, newConfig);
  }

  /// 指定埠在節點內的相對偏移（以節點左上角為原點，依字型縮放係數 [fs]）。
  Offset portOffset(String portId, double fs) {
    // 除執行節點外都有一行「目前值／目前結果」（設定條與埠區之間）。
    final current = type == BlockType.execute
        ? 0.0
        : NodeMetrics.currentHeight(fs);
    final inIndex = inputs.indexWhere((p) => p.id == portId);
    if (inIndex >= 0) {
      return Offset(
        NodeMetrics.portInset(fs),
        NodeMetrics.headerHeight(fs) +
            NodeMetrics.configHeight(fs) +
            current +
            inIndex * NodeMetrics.rowHeight(fs) +
            NodeMetrics.rowHeight(fs) / 2,
      );
    }
    final outIndex = outputs.indexWhere((p) => p.id == portId);
    if (outIndex >= 0) {
      return Offset(
        NodeMetrics.width(fs) - NodeMetrics.portInset(fs),
        NodeMetrics.headerHeight(fs) +
            NodeMetrics.configHeight(fs) +
            current +
            outIndex * NodeMetrics.rowHeight(fs) +
            NodeMetrics.rowHeight(fs) / 2,
      );
    }
    return Offset.zero;
  }

  /// 序列化為 JSON（埠由型別 + 設定重建，無需儲存）。
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'x': position.dx,
    'y': position.dy,
    'config': config.toJson(),
  };

  factory FlowNode.fromJson(Map<String, dynamic> json) => FlowNode(
    id: json['id'] as String,
    type: BlockType.values.byName(json['type'] as String),
    position: Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    ),
    title: json['title'] as String?,
    config: BlockConfig.fromJson(
      (json['config'] as Map?)?.cast<String, dynamic>() ?? {},
    ),
  );
}