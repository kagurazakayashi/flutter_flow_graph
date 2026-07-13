import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/block_config.dart';
import '../models/flow_connection.dart';
import '../models/flow_node.dart';
import '../models/flow_snapshot.dart';
import '../models/global_value.dart';

// ---------------------------------------------------------------------------
// 外部資料提供者介面（由消費方實作）
// ---------------------------------------------------------------------------

/// 全域值提供者介面。
///
/// 消費方可實作此介面來提供常數／變數的查詢能力，
/// 例如從後端資料庫、本地儲存等來源讀取。
abstract class GlobalValueProvider {
  /// 以 ID 查詢全域值，找不到返回 null。
  GlobalValue? byId(int id);

  /// 取得所有全域值。
  List<GlobalValue> get all;

  /// 監聽器（變更時通知）。
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

/// 裝置參數提供者介面。
///
/// 消費方可實作此介面來提供裝置感測器讀數，
/// 用於讀取節點和觸發節點的裝置數值來源。
abstract class DeviceValueProvider {
  /// 以 SN 和參數 ID 查詢當前讀數（可能為 null）。
  double? valueOf(String serial, int pollutantId);

  /// 指定參數的顯示單位。
  String displayUnitOf(String serial, int pollutantId);

  /// 監聽器（讀數變更時通知）。
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

// ---------------------------------------------------------------------------
// 內建全域值提供者（預設空實作）
// ---------------------------------------------------------------------------

/// 預設空全域值提供者（不與任何後端連線）。
class DefaultGlobalValueProvider extends ChangeNotifier
    implements GlobalValueProvider {
  final List<GlobalValue> _values = [];

  @override
  GlobalValue? byId(int id) {
    try {
      return _values.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<GlobalValue> get all => List.unmodifiable(_values);

  /// 批次設定全域值（通常在載入快照時調用）。
  void setAll(List<GlobalValue> values) {
    _values
      ..clear()
      ..addAll(values);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// FlowController（核心狀態管理）
// ---------------------------------------------------------------------------

/// 低程式碼畫布的狀態管理：維護節點、連線、視口（平移／縮放）以及拖線預覽。
///
/// 所有狀態變更都透過 [notifyListeners] 通知監聽者重建 UI。
/// 支援：
/// - 節點增刪改、拖放移動
/// - 連線建立／刪除、拖線預覽
/// - 無限畫布平移與縮放
/// - 快照匯入／匯出（JSON 序列化）
/// - 單節點測試求值
/// - 動態輸入埠管理
class FlowController extends ChangeNotifier {
  FlowController({
    GlobalValueProvider? globalValues,
    DeviceValueProvider? deviceProvider,
  }) : _globalValues = globalValues ?? DefaultGlobalValueProvider(),
       _deviceProvider = deviceProvider;

  // ---- 外部依賴 ----

  final GlobalValueProvider _globalValues;
  final DeviceValueProvider? _deviceProvider;

  /// 全域值提供者（常數／變數）。
  GlobalValueProvider get globalValues => _globalValues;

  /// 裝置數值提供者（感測器讀數）。
  DeviceValueProvider? get deviceProvider => _deviceProvider;

  // ---- 節點與連線 ----

  /// 畫布上的全部節點。
  final Map<String, FlowNode> nodes = <String, FlowNode>{};

  /// 節點之間的連線。
  final List<FlowConnection> connections = <FlowConnection>[];

  /// 是否有未儲存的修改（各修改操作置位，儲存／載入快照後清除）。
  bool _isDirty = false;
  bool get isDirty => _isDirty;

  /// 標記為已修改。
  void markDirty() => _isDirty = true;

  /// 標記已儲存並通知（「未儲存」指示器據此消失）。
  void markSaved() {
    _isDirty = false;
    notifyListeners();
  }

  // ---- 視口狀態 ----

  /// 視口平移量（螢幕座標）。
  Offset panOffset = Offset.zero;

  /// 視口縮放比例。
  double scale = 1.0;

  /// 節點內字型縮放（畫布工具列可調，僅 UI 顯示，不參與儲存）。
  double fontScale = 1.2;

  /// 設定節點內字型縮放並通知重繪。
  void setFontScale(double v) {
    fontScale = v;
    notifyListeners();
  }

  /// 畫布視口在螢幕上的全域原點（由 NodeCanvas 渲染後維護）。
  Offset canvasOrigin = Offset.zero;

  /// 畫布視口尺寸（由 NodeCanvas 渲染後維護）。
  Size viewportSize = Size.zero;

  /// 視口是否已完成首次初始化（用於初始時讓世界原點居中）。
  bool viewInitialized = false;

  // ---- 選取與互動狀態 ----

  /// 當前選取的節點／連線。
  String? selectedNodeId;
  String? selectedConnectionId;

  /// 滑鼠懸停的節點（用於邊框高亮）。
  String? hoveredNodeId;

  /// 正在拖曳的節點（用於邊框高亮）。
  String? draggingNodeId;


  // ---- 拖線預覽狀態 ----

  String? _draftFromNodeId;
  String? _draftFromPortId;
  Offset? _draftEnd;

  /// 拖線時當前懸停命中的輸入埠（作為可連線目標）。
  String? draftTargetNodeId;
  String? draftTargetPortId;

  String? get draftFromNodeId => _draftFromNodeId;
  String? get draftFromPortId => _draftFromPortId;
  Offset? get draftEnd => _draftEnd;

  /// 是否正在拖線。
  bool get isDrafting => _draftFromNodeId != null;

  // ---- 內部計數器 ----

  int _seq = 0;

  String _nextId(String prefix) => '$prefix-${_seq++}';

  // ---------------------------------------------------------------------------
  // 座標轉換
  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  // 座標轉換
  // ---------------------------------------------------------------------------

  /// 螢幕座標 -> 世界座標。
  Offset screenToWorld(Offset screen) =>
      (screen - canvasOrigin - panOffset) / scale;


  /// 世界座標 -> 畫布局部座標（用於定位節點 Widget）。
  Offset worldToCanvas(Offset world) => world * scale + panOffset;


  // ---------------------------------------------------------------------------
  // 視口操作
  // ---------------------------------------------------------------------------

  /// 平移視口。
  void panBy(Offset delta) {
    panOffset += delta;
    notifyListeners();
  }


  /// 以 [focus] 為焦點縮放視口。
  void zoomAt(double factor, Offset focus) {
    final oldScale = scale;
    scale = (scale * factor).clamp(0.15, 4.0);
    if (scale != oldScale) {
      panOffset = focus - (focus - panOffset) * (scale / oldScale);
      notifyListeners();
    }
  }


  /// 重設視口（回到初始狀態）。
  void resetView() {
    if (viewportSize == Size.zero) return;
    scale = 1.0;
    panOffset = viewportSize.center(Offset.zero) / 2;
    notifyListeners();
  }


  // ---------------------------------------------------------------------------
  // 節點操作
  // ---------------------------------------------------------------------------

  /// 每個畫布只能有一個觸發節點（流程起點）。
  bool get hasTriggerNode =>
      nodes.values.any((n) => n.type == BlockType.trigger);


  /// 新增節點到畫布；觸發節點已存在時拒絕（返回 null，畫布只能有一個觸發節點）。
  FlowNode? addNode(BlockType type, Offset position) {
    if (type == BlockType.trigger && hasTriggerNode) {
      return null; // 每個畫布只能有一個觸發節點
    }
    final node = FlowNode(id: _nextId('node'), type: type, position: position);
    nodes[node.id] = node;
    _isDirty = true;
    notifyListeners();
    return node;
  }


  /// 刪除節點，同時清理相關連線。
  void removeNode(String id) {
    nodes.remove(id);
    // 被刪除節點作為源發出的連線會讓目標運算節點埠失去來源，
    // 若該埠僅靠連線取值（無輸入框值），連線刪除後自動刪除埠。
    final removed = connections
        .where((c) => c.fromNodeId == id || c.toNodeId == id)
        .toList();
    connections.removeWhere((c) => c.fromNodeId == id || c.toNodeId == id);
    for (final c in removed) {
      if (c.fromNodeId == id) {
        _maybeRemoveExtraInput(c.toNodeId, c.toPortId);
      }
    }
    if (selectedNodeId == id) {
      selectedNodeId = null;
    }
    _isDirty = true;
    notifyListeners();
  }


  /// 移動節點。
  void moveNode(String id, Offset position) {
    final node = nodes[id];
    if (node == null) return;
    node.position = position;
    _isDirty = true;
    notifyListeners();
  }


  /// 更新節點的設定（判斷運算子、運算公式、組合邏輯、執行動作等），
  /// 並清理指向已不存在埠的連線（埠結構可能隨設定變化）。
  void updateNodeConfig(String id, BlockConfig config) {
    final node = nodes[id];
    if (node == null) return;
    node.updateConfig(config);
    final validInputs = node.inputs.map((p) => p.id).toSet();
    final validOutputs = node.outputs.map((p) => p.id).toSet();
    connections.removeWhere(
      (c) =>
          (c.fromNodeId == id && !validOutputs.contains(c.fromPortId)) ||
          (c.toNodeId == id && !validInputs.contains(c.toPortId)),
    );
    _isDirty = true;
    notifyListeners();
  }


  /// 更新某輸入埠的內聯輸入值（節點中輸入框，如運算節點 x/a~i）。
  /// 埠已連線時以 from 傳值為準；空值表示未填寫。
  void updateInputValue(String nodeId, String portId, String value) {
    final node = nodes[nodeId];
    if (node == null) return;
    final v = value.trim();
    if (v.isEmpty) {
      node.config.inputValues.remove(portId);
    } else {
      node.config.inputValues[portId] = v;
    }
    _isDirty = true;
    notifyListeners();
  }


  // ---- 動態輸入埠 ----

  /// 動態入口節點「新增輸入」：從型別標籤池取最小空缺標號新增一個輸入埠。
  /// 成功返回新埠 ID；已滿返回 null。
  String? addDynamicInput(String nodeId) {
    final node = nodes[nodeId];
    if (node == null || !isDynamicInputType(node.type)) return null;
    final next = nextExtraInputLabel(nodeId);
    if (next == null) return null;
    node.config.extraInputPorts = [...node.config.extraInputPorts, next];
    node.updateConfig(node.config);
    _isDirty = true;
    notifyListeners();
    return next;
  }


  /// 動態入口節點下一個可新增的輸入埠標籤（標籤池中最小空缺標號）；已滿返回 null。
  String? nextExtraInputLabel(String nodeId) {
    final node = nodes[nodeId];
    if (node == null || !isDynamicInputType(node.type)) return null;
    for (final id in extraInputPortIds(node.type)) {
      if (!node.config.extraInputPorts.contains(id)) return id;
    }
    return null;
  }


  /// 動態入口節點「新增點」（最後一個可連線點）的世界座標；輸入已滿時返回 null。
  /// 連線落在此點會自動新增輸入埠並連到新埠。
  Offset? addPointPosition(String nodeId) {
    final node = nodes[nodeId];
    if (node == null || !isDynamicInputType(node.type)) return null;
    if (node.inputs.length >= maxDynamicInputs(node.type)) return null;
    final current = node.type == BlockType.execute
        ? 0.0
        : NodeMetrics.currentHeight(fontScale);
    return node.position +
        Offset(
          NodeMetrics.portInset(fontScale),
          NodeMetrics.headerHeight(fontScale) +
              NodeMetrics.configHeight(fontScale) +
              current +
              node.inputs.length * NodeMetrics.rowHeight(fontScale) +
              NodeMetrics.rowHeight(fontScale) / 2,
        );
  }


  /// 連線被刪除後清理動態入口節點的輸入埠：
  /// 目標埠不是恆在首埠、未填寫輸入框值、且不再有任何連線時，
  /// 自動刪除該埠；保留空缺標號，下次新增從空缺標號開始。
  void _maybeRemoveExtraInput(String nodeId, String portId) {
    final node = nodes[nodeId];
    if (node == null || !isDynamicInputType(node.type)) return;
    if (portId == defaultInputPortId(node.type)) return;
    if (!node.config.extraInputPorts.contains(portId)) return;
    if ((node.config.inputValues[portId] ?? '').isNotEmpty) return;
    if (connections.any((c) => c.toNodeId == nodeId && c.toPortId == portId)) {
      return;
    }
    node.config.extraInputPorts.remove(portId);
    node.config.inputValues.remove(portId);
    node.config.secondaryConditions.remove(portId);
    node.updateConfig(node.config);
  }


  /// 輸入埠的內聯輸入框是否應隱藏：
  /// 埠已連線、連線另一端實際傳出值且為數值時才隱藏（連線提供數值；
  /// 僅連了線但未傳出值的（如讀取節點無參數）不隱藏，仍需手動輸入）。
  bool shouldHideInputBox(String nodeId, String portId) {
    return connections.any(
      (c) =>
          c.toNodeId == nodeId &&
          c.toPortId == portId &&
          _portOutputsValue(c.fromNodeId, c.fromPortId) &&
          isNumberOutput(c.fromNodeId, c.fromPortId),
    );
  }

  /// 某節點的某輸出埠是否輸出數值（設計期依宣告型別推斷）。
  bool isNumberOutput(String nodeId, String portId) {
    final node = nodes[nodeId];
    if (node == null) return false;
    switch (node.type) {
      case BlockType.calc:
        return portId == 'out';
      case BlockType.trigger:
        return node.config.triggerType == 1;
      case BlockType.read:
        return node.config.sourceType == 'device_param';
      case BlockType.counter:
      case BlockType.judge:
      case BlockType.composite:
      case BlockType.execute:
        return false;
    }
  }


  /// 判斷某埠的輸出是否為實際傳出值（非純流程下放）。
  bool _portOutputsValue(String nodeId, String portId) {
    final node = nodes[nodeId];
    if (node == null) return false;
    switch (node.type) {
      case BlockType.trigger:
      case BlockType.read:
      case BlockType.calc:
        return true;
      case BlockType.counter:
      case BlockType.judge:
      case BlockType.composite:
        return portId == 'true' || portId == 'false' || portId == 'bool';
      case BlockType.execute:
        return false;
    }
  }


  /// 指定埠在世界座標系中的圓心位置。
  Offset portPosition(String nodeId, String portId) {
    final node = nodes[nodeId];
    if (node == null) return Offset.zero;
    return node.position + node.portOffset(portId, fontScale);
  }


  // ---------------------------------------------------------------------------
  // 選取與互動
  // ---------------------------------------------------------------------------

  /// 選取節點（取消連線選取）。
  void selectNode(String id) {
    selectedNodeId = id;
    selectedConnectionId = null;
    notifyListeners();
  }


  /// 選取連線（取消節點選取）。
  void selectConnection(String id) {
    selectedConnectionId = id;
    selectedNodeId = null;
    notifyListeners();
  }


  /// 清除所有選取。
  void clearSelection() {
    selectedNodeId = null;
    selectedConnectionId = null;
    notifyListeners();
  }


  /// 設定滑鼠懸停節點。
  void setHoverNode(String? id) {
    hoveredNodeId = id;
    notifyListeners();
  }


  /// 設定正在拖曳的節點。
  void setDraggingNode(String? id) {
    draggingNodeId = id;
    notifyListeners();
  }


  // ---------------------------------------------------------------------------
  // 連線操作
  // ---------------------------------------------------------------------------

  /// 開始拖線（從輸出埠拖出）。
  void beginDraft(String nodeId, String portId) {
    _draftFromNodeId = nodeId;
    _draftFromPortId = portId;
    _draftEnd = portPosition(nodeId, portId);
    notifyListeners();
  }


  /// 更新拖線終點（世界座標）。
  void updateDraft(Offset world) {
    _draftEnd = world;
    notifyListeners();
  }


  /// 結束拖線：若命中輸入埠則建立連線。
  void endDraft(Offset world) {
    if (_draftFromNodeId == null || _draftFromPortId == null) {
      cancelDraft();
      return;
    }
    final target = _hitTestInputPort(world);
    if (target != null) {
      _addConnection(_draftFromNodeId!, _draftFromPortId!, target.nodeId, target.portId);
    }
    cancelDraft();
  }


  /// 取消拖線。
  void cancelDraft() {
    _draftFromNodeId = null;
    _draftFromPortId = null;
    _draftEnd = null;
    draftTargetNodeId = null;
    draftTargetPortId = null;
    notifyListeners();
  }


  /// 建立連線（含自動新增動態輸入埠、去重）。
  void _addConnection(String fromNodeId, String fromPortId, String toNodeId, String toPortId) {
    // 不允許自連。
    if (fromNodeId == toNodeId) return;
    // 不允許重複連線。
    if (connections.any((c) =>
        c.fromNodeId == fromNodeId &&
        c.fromPortId == fromPortId &&
        c.toNodeId == toNodeId &&
        c.toPortId == toPortId)) {
      return;
    }
    // 目標埠為「新增點」時，自動新增一個輸入埠。
    if (toPortId == addPointPortId) {
      final added = addDynamicInput(toNodeId);
      if (added == null) return;
      toPortId = added;
    }
    connections.add(FlowConnection(
      id: _nextId('conn'),
      fromNodeId: fromNodeId,
      fromPortId: fromPortId,
      toNodeId: toNodeId,
      toPortId: toPortId,
    ));
    _isDirty = true;
    notifyListeners();
  }


  /// 刪除連線。
  void removeConnection(String id) {
    final conn = connections.where((c) => c.id == id).firstOrNull;
    if (conn != null) {
      _maybeRemoveExtraInput(conn.toNodeId, conn.toPortId);
    }
    connections.removeWhere((c) => c.id == id);
    if (selectedConnectionId == id) {
      selectedConnectionId = null;
    }
    _isDirty = true;
    notifyListeners();
  }


  /// 命中測試：世界座標 [world] 是否落在某個輸入埠的範圍內。
  ({String nodeId, String portId})? _hitTestInputPort(Offset world) {
    const threshold = 24.0;
    ({String nodeId, String portId})? best;
    var bestDist = double.infinity;

    for (final node in nodes.values) {
      for (final port in node.inputs) {
        final center = node.position + node.portOffset(port.id, fontScale);
        final d = (center - world).distance;
        if (d < threshold && d < bestDist) {
          bestDist = d;
          best = (nodeId: node.id, portId: port.id);
        }
      }
      // 也檢查「新增點」。
      final add = addPointPosition(node.id);
      if (add != null) {
        final d = (add - world).distance;
        if (d < threshold && d < bestDist) {
          bestDist = d;
          best = (nodeId: node.id, portId: addPointPortId);
        }
      }
    }
    return bestDist < threshold ? best : null;
  }


  // ---------------------------------------------------------------------------
  // 快照（序列化）
  // ---------------------------------------------------------------------------

  /// 將當前畫布狀態匯出為快照。
  FlowSnapshot toSnapshot() => FlowSnapshot(
    nodes: nodes.values.map((n) => n.toJson()).toList(),
    connections: connections.map((c) => c.toJson()).toList(),
  );


  /// 從快照載入畫布狀態（清除現有狀態）。
  void loadSnapshot(FlowSnapshot snapshot) {
    nodes.clear();
    connections.clear();
    _seq = 0;
    for (final json in snapshot.nodes) {
      final node = FlowNode.fromJson(json);
      nodes[node.id] = node;
      // 確保 seq 計數器大於已載入的 ID。
      final idNum = int.tryParse(node.id.replaceFirst('node-', ''));
      if (idNum != null && idNum >= _seq) _seq = idNum + 1;
    }
    for (final json in snapshot.connections) {
      connections.add(FlowConnection.fromJson(json));
      final idNum = int.tryParse(
        FlowConnection.fromJson(json).id.replaceFirst('conn-', ''),
      );
      if (idNum != null && idNum >= _seq) _seq = idNum + 1;
    }
    _isDirty = false;
    clearSelection();
    if (!viewInitialized) {
      resetView();
      viewInitialized = true;
    }
    notifyListeners();
  }

// 釋放資源
  // ---------------------------------------------------------------------------

}
