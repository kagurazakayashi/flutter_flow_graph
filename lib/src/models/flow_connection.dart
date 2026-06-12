/// 節點之間的連線（from 輸出埠 -> to 輸入埠）。
class FlowConnection {
  FlowConnection({
    required this.id,
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.toPortId,
  });

  final String id;
  final String fromNodeId;
  final String fromPortId;
  final String toNodeId;
  final String toPortId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'from_node_id': fromNodeId,
    'from_port_id': fromPortId,
    'to_node_id': toNodeId,
    'to_port_id': toPortId,
  };

  factory FlowConnection.fromJson(Map<String, dynamic> json) => FlowConnection(
    id: json['id'] as String,
    fromNodeId: json['from_node_id'] as String,
    fromPortId: json['from_port_id'] as String,
    toNodeId: json['to_node_id'] as String,
    toPortId: json['to_port_id'] as String,
  );
}