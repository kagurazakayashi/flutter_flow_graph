/// 畫布快照（節點 + 連線的可序列化狀態），用於流程的儲存／恢復。
class FlowSnapshot {
  const FlowSnapshot({required this.nodes, required this.connections});

  /// 序列化後的節點（`FlowNode.toJson`）。
  final List<Map<String, dynamic>> nodes;

  /// 序列化後的連線（`FlowConnection.toJson`）。
  final List<Map<String, dynamic>> connections;

  static const FlowSnapshot empty = FlowSnapshot(nodes: [], connections: []);

  bool get isEmpty => nodes.isEmpty;

  Map<String, dynamic> toJson() => {'nodes': nodes, 'connections': connections};

  factory FlowSnapshot.fromJson(Map<String, dynamic> json) => FlowSnapshot(
    nodes: (json['nodes'] as List<dynamic>? ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(),
    connections: (json['connections'] as List<dynamic>? ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(),
  );
}