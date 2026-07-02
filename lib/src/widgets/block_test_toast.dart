import 'package:flutter/material.dart';

/// 節點測試結果 Toast 控制器。
///
/// 在畫面底部顯示測試結果浮層，支援複製與關閉。
/// 使用 [show] 顯示，[hide] 關閉。
class BlockTestToast {
  BlockTestToast._();

  static OverlayEntry? _entry;

  /// 顯示測試結果 Toast。
  static void show(BuildContext context, Widget content) {
    hide();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 24,
        left: 24,
        child: content,
      ),
    );
    overlay.insert(_entry!);
  }

  /// 關閉測試結果 Toast。
  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}