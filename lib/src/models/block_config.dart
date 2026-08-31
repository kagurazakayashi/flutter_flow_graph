/// 節點設定（BlockConfig）。
///
/// 定義各節點型別的設定參數，包括判斷運算子、運算公式、組合邏輯、
/// 讀取來源、觸發條件、執行動作等。所有設定均可序列化為 JSON。
library;

import 'flow_node.dart';

class BlockConfig {
  BlockConfig({
    this.check = false,
    this.formula = '',
    this.judgeMode = 'range',
    this.judgeOperator = 'between',
    this.logic = 'AND',
    this.sourceType = 'none',
    this.sourceSerial,
    this.sourcePollutantId,
    this.sourceGlobalValueId,
    this.triggerType,
    this.triggerSerial,
    this.triggerPollutantId,
    this.triggerVariableId,
    this.cronExpression,
    List<String>? extraInputPorts,
    Map<String, String>? inputValues,
    this.aValue,
    this.bValue,
    this.countMode = 'increment',
    this.countValue = '1',
    Map<String, String>? secondaryConditions,
    List<Map<String, dynamic>>? actions,
  })  : extraInputPorts = extraInputPorts ?? [],
        inputValues = inputValues ?? {},
        secondaryConditions = secondaryConditions ?? {},
        actions = actions ?? [];

  // ---- 通用 ----

  /// 是否啟用檢查（測試時參與校驗）。
  bool check;

  // ---- 讀取節點 ----

  /// 讀取來源類型：none / device_param / constant / variable。
  String sourceType;

  /// 裝置序號（sourceType == 'device_param' 時使用）。
  String? sourceSerial;

  /// 檢測參數 ID（sourceType == 'device_param' 時使用）。
  int? sourcePollutantId;

  /// 全域值 ID（sourceType == 'constant' 或 'variable' 時使用）。
  int? sourceGlobalValueId;

  // ---- 運算節點 ----

  /// 計算公式（支援 x, a~i 等埠變數）。
  String formula;

  // ---- 判斷節點 ----

  /// 判斷模式：range（範圍）／single（單值）。
  String judgeMode;

  /// 判斷運算子：
  /// 範圍模式：between / not_between；
  /// 單值模式：> / >= / < / <= / == / !=。
  String judgeOperator;

  /// 判斷值 a（範圍模式的下限，或單值模式的比較值）。
  double? aValue;

  /// 判斷值 b（範圍模式的上限，單值模式不使用）。
  double? bValue;

  // ---- 組合判斷節點 ----

  /// 組合邏輯：AND / OR / NOT。
  String logic;

  // ---- 觸發節點 ----

  /// 觸發類型：1 裝置數值／2 變數值／3 時間觸發／4 條件觸發。
  int? triggerType;

  String? triggerSerial;
  int? triggerPollutantId;
  int? triggerVariableId;

  /// Cron 表示式（時間觸發時使用）。
  String? cronExpression;

  // ---- 計數器節點 ----

  /// 計數模式：increment（遞增）／decrement（遞減）。
  String countMode;

  /// 增量值（預設 "1"）。
  String countValue;

  // ---- 動態入口 ----

  /// 動態入口節點已啟用的額外輸入埠 ID 列表。
  List<String> extraInputPorts;

  /// 輸入埠的內聯輸入值（key = 埠 ID，value = 輸入值）。
  Map<String, String> inputValues;

  /// 次要條件（key = 埠 ID，value = 條件值）。
  /// 判斷值的額外條件（AND 關係）：埠有值且滿足條件時整體條件才為真。
  Map<String, String> secondaryConditions;

  // ---- 執行節點 ----

  /// 執行動作列表（郵件、HTTP 等）。
  List<Map<String, dynamic>> actions;

  // ---- 輔助常數 ----

  /// 範圍判斷運算子列表。
  static const List<String> rangeOperators = ['between', 'not_between'];

  /// 單值判斷運算子列表。
  static const List<String> singleOperators = [
    '>', '>=', '<', '<=', '==', '!=',
  ];

  Map<String, dynamic> toJson() => {
    if (check) 'check': check,
    if (sourceType != 'none') 'source_type': sourceType,
    if (sourceSerial != null) 'source_serial': sourceSerial,
    if (sourcePollutantId != null) 'source_pollutant_id': sourcePollutantId,
    if (sourceGlobalValueId != null)
      'source_global_value_id': sourceGlobalValueId,
    if (formula.isNotEmpty) 'formula': formula,
    if (judgeMode != 'range') 'judge_mode': judgeMode,
    if (judgeOperator != 'between') 'judge_operator': judgeOperator,
    if (aValue != null) 'a_value': aValue,
    if (bValue != null) 'b_value': bValue,
    if (logic != 'AND') 'logic': logic,
    if (triggerType != null) 'trigger_type': triggerType,
    if (triggerSerial != null) 'trigger_serial': triggerSerial,
    if (triggerPollutantId != null) 'trigger_pollutant_id': triggerPollutantId,
    if (triggerVariableId != null) 'trigger_variable_id': triggerVariableId,
    if (cronExpression != null) 'cron_expression': cronExpression,
    if (countMode != 'increment') 'count_mode': countMode,
    if (countValue != '1') 'count_value': countValue,
    if (extraInputPorts.isNotEmpty) 'extra_input_ports': extraInputPorts,
    if (inputValues.isNotEmpty) 'input_values': inputValues,
    if (secondaryConditions.isNotEmpty)
      'secondary_conditions': secondaryConditions,
    if (actions.isNotEmpty) 'actions': actions,
  };

  factory BlockConfig.fromJson(Map<String, dynamic> json) => BlockConfig(
    check: json['check'] as bool? ?? false,
    sourceType: json['source_type'] as String? ?? 'none',
    sourceSerial: json['source_serial'] as String?,
    sourcePollutantId: json['source_pollutant_id'] as int?,
    sourceGlobalValueId: json['source_global_value_id'] as int?,
    formula: json['formula'] as String? ?? '',
    judgeMode: json['judge_mode'] as String? ?? 'range',
    judgeOperator: json['judge_operator'] as String? ?? 'between',
    aValue: (json['a_value'] as num?)?.toDouble(),
    bValue: (json['b_value'] as num?)?.toDouble(),
    logic: json['logic'] as String? ?? 'AND',
    triggerType: json['trigger_type'] as int?,
    triggerSerial: json['trigger_serial'] as String?,
    triggerPollutantId: json['trigger_pollutant_id'] as int?,
    triggerVariableId: json['trigger_variable_id'] as int?,
    cronExpression: json['cron_expression'] as String?,
    countMode: json['count_mode'] as String? ?? 'increment',
    countValue: json['count_value'] as String? ?? '1',
    extraInputPorts: (json['extra_input_ports'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    inputValues: (json['input_values'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)) ??
        {},
    secondaryConditions: (json['secondary_conditions'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)) ??
        {},
    actions: (json['actions'] as List<dynamic>?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        [],
  );
}

/// 產生設定摘要文字（顯示在節點設定條上）。
/// [nameOf] 為可選的回呼，用於將全域值 ID 轉換為顯示名稱。
String configSummary(BlockType type, BlockConfig config,
    {String Function(int id)? nameOf}) {
  switch (type) {
    case BlockType.calc:
      return config.formula.isEmpty ? '（無公式）' : config.formula;
    case BlockType.judge:
      final mode = config.judgeMode == 'range' ? '範圍' : '單值';
      return '$mode ${config.judgeOperator}';
    case BlockType.composite:
      return config.logic;
    case BlockType.read:
      switch (config.sourceType) {
        case 'device_param':
          final sn = config.sourceSerial ?? '';
          final pid = config.sourcePollutantId?.toString() ?? '';
          return '裝置 $sn / $pid';
        case 'constant':
        case 'variable':
          final id = config.sourceGlobalValueId;
          final name = id != null ? (nameOf?.call(id) ?? '$id') : '—';
          return config.sourceType == 'constant' ? '常數 $name' : '變數 $name';
        default:
          return '無參數';
      }
    case BlockType.trigger:
      switch (config.triggerType) {
        case 1:
          return '裝置數值';
        case 2:
          return '變數值';
        case 3:
          return '時間觸發';
        default:
          return '未設定';
      }
    case BlockType.counter:
      return config.countMode == 'increment' ? '遞增 ${config.countValue}' : '遞減 ${config.countValue}';
    case BlockType.execute:
      return '${config.actions.length} 個動作';
  }
}