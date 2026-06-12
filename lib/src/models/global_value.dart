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
