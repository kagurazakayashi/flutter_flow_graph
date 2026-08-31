import 'package:flutter/foundation.dart';

/// 畫布編輯器設定（工具列「設定」入口開啟）。
///
/// 目前包含一項：縮放提示（畫布底部操作提示 + 滾輪縮放時的除錯提示），
/// 預設關閉，可在設定中開啟。
class EditorSettings extends ChangeNotifier {
  bool _showZoomHint = false;

  /// 是否顯示縮放提示（預設關閉）。
  bool get showZoomHint => _showZoomHint;

  set showZoomHint(bool value) {
    if (_showZoomHint == value) return;
    _showZoomHint = value;
    notifyListeners();
  }
}