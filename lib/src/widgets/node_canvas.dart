import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/editor_settings.dart';
import '../controllers/flow_controller.dart';
import '../models/flow_node.dart';
import 'node_widget.dart';

/// 網格背景繪製器（畫布局部座標），繪製點狀網格與世界原點十字標記。
class GridPainter extends CustomPainter {
  GridPainter(this.controller) : super(repaint: controller);

  final FlowController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFDDE0E3);
    final worldSpacing = 24.0 * controller.scale;
    final startX = -(controller.panOffset.dx % worldSpacing);
    final startY = -(controller.panOffset.dy % worldSpacing);

    for (var x = startX; x < size.width; x += worldSpacing) {
      for (var y = startY; y < size.height; y += worldSpacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }

    // 畫布原點（世界座標 (0,0)）深灰色十字標記。
    final origin = controller.panOffset;
    final crossPaint = Paint()
      ..color = const Color(0xFF424242)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    const r = 14.0;
    canvas.drawLine(
      origin - const Offset(r, 0),
      origin + const Offset(r, 0),
      crossPaint,
    );
    canvas.drawLine(
      origin - const Offset(0, r),
      origin + const Offset(0, r),
      crossPaint,
    );
    canvas.drawCircle(origin, 3.5, crossPaint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => true;
}

/// 連線層（畫布局部座標），繪製已建立的連線與拖線預覽。
class ConnectionPainter extends CustomPainter {
  ConnectionPainter(this.controller) : super(repaint: controller);

  final FlowController controller;

  @override
  void paint(Canvas canvas, Size size) {
    // 已建立連線（世界座標 -> 畫布局部座標）。
    for (final conn in controller.connections) {
      final from = controller.worldToCanvas(
        controller.portPosition(conn.fromNodeId, conn.fromPortId),
      );
      final to = controller.worldToCanvas(
        controller.portPosition(conn.toNodeId, conn.toPortId),
      );
      final selected = controller.selectedConnectionId == conn.id;
      final color = selected
          ? const Color(0xFF1565C0)
          : _lineColor(controller, conn.fromPortId);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3.5 : 2.5
        ..strokeCap = StrokeCap.round;

      final path = _connectionPath(from, to);
      canvas.drawPath(path, paint);
    }

  Path _connectionPath(Offset from, Offset to) {
    final dx = math.max((to.dx - from.dx).abs() * 0.5, 50.0);
    return Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx + dx, from.dy, to.dx - dx, to.dy, to.dx, to.dy);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => true;
}

/// 連線顏色（依埠語義）：true 埠綠色、false 埠紅色、其餘灰藍色。
Color _lineColor(FlowController controller, String portId) {
  switch (portId) {
    case 'true':
      return const Color(0xFF4CAF50);
    case 'false':
      return const Color(0xFFF44336);
    default:
      return const Color(0xFF78909C);
  }
}

/// 在貝塞爾曲線上取樣若干點，用於命中測試（點擊連線選取）。
List<Offset> bezierPoints(Offset from, Offset to) {
  final dx = math.max((to.dx - from.dx).abs() * 0.5, 50.0);
  const steps = 40;
  final pts = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = _cubicBezier(from.dx, from.dx + dx, to.dx - dx, to.dx, t);
    final y = _cubicBezier(from.dy, from.dy, to.dy, to.dy, t);
    pts.add(Offset(x, y));
  }
  return pts;
}

double _cubicBezier(double a, double b, double c, double d, double t) {
  final u = 1 - t;
  return u * u * u * a +
      3 * u * u * t * b +
      3 * u * t * t * c +
      t * t * t * d;
}

/// 低程式碼畫布：負責平移／縮放、繪製網格與連線、放置節點。
///
/// 使用方式：
/// ```dart
/// NodeCanvas(
///   controller: myFlowController,
///   settings: myEditorSettings,
///   onExitTextInput: () => FocusScope.of(context).unfocus(),
/// )
/// ```
class NodeCanvas extends StatefulWidget {
  const NodeCanvas({
    super.key,
    required this.controller,
    this.settings,
    this.onExitTextInput,
    this.onNodeConfigRequested,
  });

  final FlowController controller;

  /// 編輯器設定（縮放提示開關；未傳時縮放提示不顯示）。
  final EditorSettings? settings;

  /// 點擊連線選取時回呼（由編輯器把鍵盤焦點從文字框交還畫布，
  /// 使 Delete / Backspace 能刪除選取的連線）。
  final VoidCallback? onExitTextInput;

  /// 節點設定請求回呼（消費方提供節點型別 -> 設定對話框的對應邏輯）。
  final void Function(BuildContext context, String nodeId)? onNodeConfigRequested;

  @override
  State<NodeCanvas> createState() => _NodeCanvasState();
}

class _NodeCanvasState extends State<NodeCanvas> {
  final GlobalKey _canvasKey = GlobalKey();

  FlowController get controller => widget.controller;

  /// 手勢累計縮放基線（ScaleGestureRecognizer 的 scale 相對手勢起點；
  /// 用相鄰兩幀之比得到增量因子餵給 [FlowController.zoomAt]）。
  double _lastScale = 1.0;

  /// 上一幀手勢手指數（手指數變化的一幀焦點／跨度會跳變，需重新錨定）。
  int _lastPointerCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanvasOrigin());
  }

  /// 更新畫布在螢幕上的全域原點與視口尺寸，並在首次初始化時讓原點居中。
  void _updateCanvasOrigin() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.attached) {
      controller.canvasOrigin = box.localToGlobal(Offset.zero);
      controller.viewportSize = box.size;
      if (!controller.viewInitialized) {
        controller.viewInitialized = true;
        controller.resetView();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ClipRect(
          key: _canvasKey,
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 網格背景（畫布局部座標）。
                  Positioned.fill(
                    child: CustomPaint(painter: GridPainter(controller)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPointerSignal(Object event) {
    // 處理滑鼠滾輪縮放。
    // Flutter 3.38+ 中 PointerSignalEvent 已移除，改用動態屬性存取。
    try {
      final scrollDelta = (event as dynamic).scrollDelta as Offset?;
      if (scrollDelta != null) {
        final position = (event as dynamic).position as Offset?;
        if (position != null) {
          final factor = math.pow(1.0015, -scrollDelta.dy).toDouble();
          final pointerGlobal = position + controller.canvasOrigin;
          controller.zoomAt(factor, pointerGlobal);
        }
      }
    } catch (_) {
      // 忽略無法轉換的事件（例如觸控板手勢）。
    }
  }


  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
    _lastPointerCount = details.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount != _lastPointerCount) {
      _lastPointerCount = details.pointerCount;
      _lastScale = details.scale;
      return;
    }
    if (details.pointerCount >= 2) {
      final double factor =
          (details.scale / _lastScale).clamp(0.5, 2.0).toDouble();
      _lastScale = details.scale;
      if (factor != 1.0) {
        final focalGlobal = details.localFocalPoint + controller.canvasOrigin;
        controller.zoomAt(factor, focalGlobal);
      }
    }
    if (details.focalPointDelta != Offset.zero) {
      controller.panBy(details.focalPointDelta);
    }
  }
  void _onTapUp(TapUpDetails details) {
    controller.clearSelection();
  }


}