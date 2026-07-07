import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/flow_connection.dart';
import '../models/flow_node.dart';

class FlowController extends ChangeNotifier {
  FlowController();

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

  /// 刪除節點，同時清理與之相關的連線。
  void removeNode(String id) {
    nodes.remove(id);
    connections.removeWhere((c) => c.fromNodeId == id || c.toNodeId == id);
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


  /// 指定埠在世界座標系中的圓心位置。
  Offset portPosition(String nodeId, String portId) {
    final node = nodes[nodeId];
    if (node == null) return Offset.zero;
    return node.position + node.portOffset(portId, fontScale);
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

  /// 建立連線。
  void _addConnection(String fromNodeId, String fromPortId, String toNodeId, String toPortId) {
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
    }
    return bestDist < threshold ? best : null;
  }

// 釋放資源
  // ---------------------------------------------------------------------------

}
