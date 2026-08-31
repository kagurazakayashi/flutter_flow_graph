import 'package:flutter/material.dart';

import '../controllers/flow_controller.dart';
import '../i18n/gen/app_localizations.dart';
import '../models/flow_node.dart';

/// 埠圓點。輸入埠作為連線落點，輸出埠可拖曳建立連線。
/// [isTarget] 為 true 時表示拖線命中此輸入埠，圓點高亮放大。
/// [onTap] 提供時，點擊輸出埠圓點可編輯該埠的輸出設定（開啟節點設定）。
class PortWidget extends StatelessWidget {
  const PortWidget({
    super.key,
    required this.nodeId,
    required this.port,
    required this.controller,
    required this.color,
    this.isTarget = false,
    this.onTap,
  });

  final String nodeId;
  final NodePort port;
  final FlowController controller;
  final Color color;
  final bool isTarget;

  /// 點擊輸出埠時的回呼（用於編輯輸出設定）。
  final VoidCallback? onTap;

  /// 埠圓點直徑（隨字型縮放）。
  double get _diameter => NodeMetrics.portRadius(controller.fontScale) * 2;

  @override
  Widget build(BuildContext context) {
    final isOutput = port.direction == PortDirection.output;

    if (isOutput) {
      // 輸出埠：拖曳建立連線；點擊（onTap 非空時）編輯輸出設定。
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanStart: (_) {
          controller.beginDraft(nodeId, port.id);
        },
        onPanUpdate: (d) =>
            controller.updateDraft(controller.screenToWorld(d.globalPosition)),
        onPanEnd: (d) {
          controller.endDraft(controller.screenToWorld(d.globalPosition));
        },
        onPanCancel: () => controller.cancelDraft(),
        child: MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: onTap == null
              ? _dot(isOutput)
              : Tooltip(
                  message: AppLocalizations.of(context).clickEditOutput,
                  child: _dot(isOutput),
                ),
        ),
      );
    }

    return _dot(isOutput);
  }

  Widget _dot(bool isOutput) {
    final highlight = isTarget;
    return AnimatedScale(
      scale: highlight ? 1.35 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          color: isOutput || highlight ? color : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: highlight ? Colors.white : color,
            width: highlight ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: highlight ? color.withValues(alpha: 0.55) : Colors.black26,
              blurRadius: highlight ? 8 : 2,
            ),
          ],
        ),
      ),
    );
  }
}