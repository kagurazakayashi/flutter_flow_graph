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

/// 格式化測試值為可讀字串。
String formatTestValue(Object? value) {
  if (value == null) return '—';
  if (value is double) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  if (value is bool) return value ? 'true' : 'false';
  return value.toString();
}

// ---------------------------------------------------------------------------
// 單節點測試結果的在地化字串提供者
// ---------------------------------------------------------------------------

/// 節點測試求值時所使用的可讀文字（說明／錯誤）提供者。
///
/// [FlowController] 在單節點測試與「目前結果」求值時，透過此介面產生
/// 使用者可見的說明與錯誤文字。消費方可以傳入自訂實作（例如基於
/// flutter_localizations / ARB 的實作）以配合自身多語言體系；
/// 未提供時使用 [DefaultBlockTestStrings] 的英文預設文字。
///
/// 使用範例：
/// ```dart
/// class MyStrings extends BlockTestStrings {
///   @override
///   String get noData => l10n.noData;
///   // ...
/// }
///
/// FlowController(strings: MyStrings());
/// ```
abstract class BlockTestStrings {
  const BlockTestStrings();

  /// 無資料（例如「—（無資料）」）。
  String get noData;

  /// 節點不存在：{nodeId}。
  String nodeNotFound(String nodeId);

  /// 未設定觸發條件。
  String get triggerNotSet;

  /// 時間觸發條件：{cron}。
  String timeTriggerCondition(String cron);

  /// 未設定 cron 表示式。
  String get cronNotSet;

  /// 無參數。
  String get noSource;

  /// 計數器節點：設計期固定顯示 0（執行期由引擎維護）。
  String get counterNote;

  /// x 輸入值不可為空。
  String get judgeXRequired;

  /// 範圍模式需要 a 和 b 兩個值。
  String get judgeRangeAB;

  /// 單值模式需要 a 比較值。
  String get judgeSingleA;

  /// 判斷說明（範圍模式）：判斷：x op [a, b] → result。
  String judgeNote(
    String x,
    String operator,
    String a,
    String b,
    String result,
  );

  /// 判斷說明（單值模式）：判斷：x op a → result。
  String judgeNoteSingle(
    String x,
    String operator,
    String a,
    String result,
  );

  /// 公式為空。
  String get calcFormulaEmpty;

  /// 公式計算錯誤：{error}。
  String calcError(String error);

  /// 埠 {portId} 未連線，視為 0。
  String portUnconnectedZero(String portId);

  /// 埠 {portId} 未連線，視為 false。
  String portUnconnectedFalse(String portId);

  /// 埠 {portId} ← {sourceNodeId}.{sourcePortId} = {value}。
  String portSource(
    String portId,
    String sourceNodeId,
    String sourcePortId,
    String value,
  );

  /// 判斷值條件：{value}。
  String judgeValueCondition(String value);

  /// 未設定執行動作。
  String get actionsEmpty;

  /// {count} 個動作待執行。
  String actionsPending(int count);

  /// 次要條件 {portId}：{condition}。
  String secondaryCondition(String portId, String condition);

  /// 除數不可為 0。
  String get divisorZero;

  /// 表示式不完整。
  String get exprIncomplete;

  /// 缺少右括號。
  String get missingRightParen;

  /// 無法解析：{token}。
  String cannotParse(String token);
}

/// [BlockTestStrings] 的預設英文實作。
///
/// 當消費方未傳入自訂 [BlockTestStrings] 時使用；文字皆為英文，
/// 可作為中性 fallback（與套件 UI 的 en 語系一致）。
class DefaultBlockTestStrings extends BlockTestStrings {
  const DefaultBlockTestStrings();

  @override
  String get noData => '— (no data)';

  @override
  String nodeNotFound(String nodeId) => 'Node not found: $nodeId';

  @override
  String get triggerNotSet => 'Trigger condition not set';

  @override
  String timeTriggerCondition(String cron) => 'Time trigger condition: $cron';

  @override
  String get cronNotSet => 'not set';

  @override
  String get noSource => 'No source';

  @override
  String get counterNote =>
      'Counter node: always shows 0 at design time (maintained by the engine at runtime)';

  @override
  String get judgeXRequired => 'Input x must not be empty';

  @override
  String get judgeRangeAB => 'Range mode requires both a and b values';

  @override
  String get judgeSingleA => 'Single-value mode requires a comparison value';

  @override
  String judgeNote(
    String x,
    String operator,
    String a,
    String b,
    String result,
  ) =>
      'Judge: $x $operator [$a, $b] → $result';

  @override
  String judgeNoteSingle(
    String x,
    String operator,
    String a,
    String result,
  ) =>
      'Judge: $x $operator $a → $result';

  @override
  String get calcFormulaEmpty => 'Formula is empty';

  @override
  String calcError(String error) => 'Formula calculation error: $error';

  @override
  String portUnconnectedZero(String portId) =>
      'Port $portId not connected, treated as 0';

  @override
  String portUnconnectedFalse(String portId) =>
      'Port $portId not connected, treated as false';

  @override
  String portSource(
    String portId,
    String sourceNodeId,
    String sourcePortId,
    String value,
  ) =>
      '$portId ← $sourceNodeId.$sourcePortId = $value';

  @override
  String judgeValueCondition(String value) => 'Judge value condition: $value';

  @override
  String get actionsEmpty => 'No execute action set';

  @override
  String actionsPending(int count) => '$count action(s) pending';

  @override
  String secondaryCondition(String portId, String condition) =>
      'Secondary condition $portId: $condition';

  @override
  String get divisorZero => 'Divisor cannot be 0';

  @override
  String get exprIncomplete => 'Expression incomplete';

  @override
  String get missingRightParen => 'Missing closing parenthesis';

  @override
  String cannotParse(String token) => 'Cannot parse: $token';
}