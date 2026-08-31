/// Flutter 流程圖編輯器（Flutter Flow Graph）
///
/// 一個高效能、零外部狀態管理依賴的 Flutter 節點圖編輯器套件。
/// 支援拖放連線、貝塞爾曲線繪製、無限畫布平移縮放，
/// 內建多種節點型別（觸發、讀取、計數器、判斷、運算、組合判斷、執行），
/// 適用於低程式碼視覺化編排、規則引擎、工作流程編輯器等場景。
library flutter_flow_graph;

export 'src/models/block_config.dart';
export 'src/models/block_test.dart';
export 'src/models/flow_connection.dart';
export 'src/models/flow_node.dart';
export 'src/models/flow_snapshot.dart';
export 'src/models/global_value.dart';
export 'src/controllers/flow_controller.dart';
export 'src/controllers/editor_settings.dart';
export 'src/widgets/node_canvas.dart';
export 'src/widgets/node_widget.dart';
export 'src/i18n/gen/app_localizations.dart';
export 'src/widgets/port_widget.dart';
export 'src/widgets/block_palette.dart';
export 'src/widgets/block_test_toast.dart';