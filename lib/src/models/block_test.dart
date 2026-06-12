/// 節點測試結果。
///
/// 包含輸出值、說明、錯誤、失敗來源等資訊，
/// 用於單節點測試功能的結果展示。
class BlockTestResult {
  BlockTestResult({
    this.output,
    this.outputText = '',
    this.notes = const [],
    this.errors = const [],
    this.sources = const [],
  });

  /// 輸出值（原始值，可能為 null）。
  final Object? output;

  /// 輸出文字（格式化後的字串）。
  final String outputText;

  /// 說明列表（測試過程中的提示資訊）。
  final List<String> notes;

  /// 錯誤列表（校驗失敗時的錯誤資訊）。
  final List<String> errors;

  /// 失敗來源列表（追蹤上游節點失敗根因）。
  final List<String> sources;

  bool get hasError => errors.isNotEmpty;
}
