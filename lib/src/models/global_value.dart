/// 全域值（常數／變數）。
///
/// 對應後端 `aa_global_value` 表的資料結構。
/// 目前在前端記憶體中維護，消費方可透過 [GlobalValueProvider] 介面接入後端。
library;

class GlobalValue {
  GlobalValue({
    required this.id,
    required this.kind,
    required this.name,
    required this.dataType,
    this.value,
  });

  final int id;

  /// constant | variable
  String kind;

  /// 名稱（同一 kind 下唯一）。
  String name;

  /// number | string | bool
  String dataType;

  /// 值（統一字串儲存，依 dataType 解析）。
  String? value;

  bool get isConstant => kind == 'constant';
  bool get isVariable => kind == 'variable';

  String get kindLabel => switch (kind) {
    'constant' => '常數',
    _ => '變數',
  };

  String get dataTypeLabel => switch (dataType) {
    'number' => '數字',
    'string' => '字串',
    'bool' => '布林值',
    _ => dataType,
  };

  /// 顯示值（空值顯示「空」）。
  String get displayValue {
    final v = value;
    if (v == null || v.isEmpty) return '空';
    return v;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'name': name,
    'data_type': dataType,
    'value': value,
  };

  factory GlobalValue.fromJson(Map<String, dynamic> json) => GlobalValue(
    id: json['id'] as int,
    kind: json['kind'] as String,
    name: json['name'] as String,
    dataType: json['data_type'] as String,
    value: json['value'] as String?,
  );
}