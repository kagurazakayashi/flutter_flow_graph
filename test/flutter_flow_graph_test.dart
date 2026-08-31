import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flow_graph/flutter_flow_graph.dart';

void main() {
  group('FlowNode', () {
    test('建立節點時應有正確的預設屬性', () {
      final node = FlowNode(
        id: 'test-1',
        type: BlockType.calc,
        position: const Offset(100, 200),
      );

      expect(node.id, 'test-1');
      expect(node.type, BlockType.calc);
      expect(node.position.dx, 100);
      expect(node.position.dy, 200);
      expect(node.inputs.isNotEmpty, true);
      expect(node.outputs.isNotEmpty, true);
    });

    test('節點序列化與反序列化應一致', () {
      final node = FlowNode(
        id: 'test-1',
        type: BlockType.calc,
        position: const Offset(100, 200),
      );
      node.config.formula = 'x + a';

      final json = node.toJson();
      final restored = FlowNode.fromJson(json);

      expect(restored.id, node.id);
      expect(restored.type, node.type);
      expect(restored.position.dx, node.position.dx);
      expect(restored.position.dy, node.position.dy);
      expect(restored.config.formula, node.config.formula);
    });
  });

  group('FlowConnection', () {
    test('建立連線時應有正確的屬性', () {
      final conn = FlowConnection(
        id: 'conn-1',
        fromNodeId: 'node-1',
        fromPortId: 'out',
        toNodeId: 'node-2',
        toPortId: 'in',
      );

      expect(conn.fromNodeId, 'node-1');
      expect(conn.fromPortId, 'out');
      expect(conn.toNodeId, 'node-2');
      expect(conn.toPortId, 'in');
    });

    test('連線序列化與反序列化應一致', () {
      final conn = FlowConnection(
        id: 'conn-1',
        fromNodeId: 'node-1',
        fromPortId: 'out',
        toNodeId: 'node-2',
        toPortId: 'in',
      );

      final json = conn.toJson();
      final restored = FlowConnection.fromJson(json);

      expect(restored.id, conn.id);
      expect(restored.fromNodeId, conn.fromNodeId);
      expect(restored.toNodeId, conn.toNodeId);
    });
  });

  group('FlowController', () {
    test('初始化時應為空畫布', () {
      final controller = FlowController();
      expect(controller.nodes.isEmpty, true);
      expect(controller.connections.isEmpty, true);
      expect(controller.scale, 1.0);
      controller.dispose();
    });

    test('新增節點', () {
      final controller = FlowController();
      controller.viewportSize = const Size(800, 600);
      controller.resetView();

      final node = controller.addNode(
        BlockType.calc,
        const Offset(100, 200),
      );

      expect(node, isNotNull);
      expect(controller.nodes.length, 1);
      expect(controller.isDirty, true);
      controller.dispose();
    });

    test('觸發節點唯一性限制', () {
      final controller = FlowController();
      controller.viewportSize = const Size(800, 600);
      controller.resetView();

      controller.addNode(BlockType.trigger, const Offset(0, 0));
      expect(controller.hasTriggerNode, true);

      final second = controller.addNode(
        BlockType.trigger,
        const Offset(100, 100),
      );
      expect(second, isNull);
      controller.dispose();
    });

    test('刪除節點時應清理連線', () {
      final controller = FlowController();
      controller.viewportSize = const Size(800, 600);
      controller.resetView();

      controller.addNode(BlockType.judge, const Offset(100, 100));
      controller.addNode(BlockType.execute, const Offset(300, 100));

      // 模擬拖線建立連線
      controller.beginDraft('node-0', 'true');
      controller.endDraft(controller.portPosition('node-1', 'trigger'));

      expect(controller.connections.length, 1);

      controller.removeNode('node-0');
      expect(controller.connections.isEmpty, true);
      controller.dispose();
    });

    test('快照匯出與匯入', () {
      final controller = FlowController();
      controller.viewportSize = const Size(800, 600);
      controller.resetView();

      controller.addNode(BlockType.calc, const Offset(100, 200));
      controller.addNode(BlockType.judge, const Offset(300, 200));

      final snapshot = controller.toSnapshot();
      expect(snapshot.nodes.length, 2);

      final controller2 = FlowController();
      controller2.viewportSize = const Size(800, 600);
      controller2.loadSnapshot(snapshot);
      expect(controller2.nodes.length, 2);
      expect(controller2.isDirty, false);

      controller.dispose();
      controller2.dispose();
    });
  });

  group('BlockConfig', () {
    test('預設設定', () {
      final config = BlockConfig();
      expect(config.formula, '');
      expect(config.judgeMode, 'range');
      expect(config.judgeOperator, 'between');
      expect(config.logic, 'AND');
      expect(config.sourceType, 'none');
    });

    test('序列化與反序列化', () {
      final config = BlockConfig()
        ..formula = 'x + a * b'
        ..judgeOperator = '>'
        ..logic = 'OR';

      final json = config.toJson();
      final restored = BlockConfig.fromJson(json);

      expect(restored.formula, 'x + a * b');
      expect(restored.judgeOperator, '>');
      expect(restored.logic, 'OR');
    });
  });

  group('NodeMetrics', () {
    test('尺寸應隨字型縮放比例變化', () {
      expect(NodeMetrics.width(1.0), 200);
      expect(NodeMetrics.width(1.5), 300);
      expect(NodeMetrics.width(2.0), 400);

      expect(NodeMetrics.headerHeight(1.0), 48);
      expect(NodeMetrics.headerHeight(1.5), 72);
    });
  });

  group('BlockType', () {
    test('內建節點型別顯示名稱不為空', () {
      for (final type in BlockType.values) {
        expect(builtinBlockTypeLabel(type).isNotEmpty, true);
        expect(builtinBlockTypeDescription(type).isNotEmpty, true);
      }
    });
  });
}