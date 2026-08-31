import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/flow_controller.dart';
import '../i18n/gen/app_localizations.dart';
import '../models/block_config.dart';
import '../models/block_test.dart';
import '../models/flow_node.dart';
import 'block_test_toast.dart';
import 'port_widget.dart';

/// 刪除按鈕直徑。
const double _deleteButtonSize = 20;

/// 刪除按鈕在節點右上角向外溢出的距離（圓心對齊節點角點）。
const double _deleteButtonOverflow = _deleteButtonSize / 2;

/// 單個視覺化節點。主體為白色，左側用色條標識型別，
/// 左右兩側為輸入／輸出埠，支援拖曳與選取。
class NodeWidget extends StatelessWidget {
  const NodeWidget({
    super.key,
    required this.node,
    required this.controller,
    this.onExitTextInput,
    this.onConfigRequested,
  });

  /// 依系統語言回傳節點型別標籤。
  static String _localizedBlockLabel(BuildContext context, BlockType type) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      BlockType.trigger => l10n.blockTypeTrigger,
      BlockType.read => l10n.blockTypeRead,
      BlockType.counter => l10n.blockTypeCounter,
      BlockType.judge => l10n.blockTypeJudge,
      BlockType.calc => l10n.blockTypeCalc,
      BlockType.composite => l10n.blockTypeComposite,
      BlockType.execute => l10n.blockTypeExecute,
    };
  }

  /// 依系統語言回傳節點型別簡述。
  static String _localizedDescription(BuildContext context, BlockType type) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      BlockType.trigger => l10n.descTrigger,
      BlockType.read => l10n.descRead,
      BlockType.counter => l10n.descCounter,
      BlockType.judge => l10n.descJudge,
      BlockType.calc => l10n.descCalc,
      BlockType.composite => l10n.descComposite,
      BlockType.execute => l10n.descExecute,
    };
  }

  /// 埠標籤地化：`in` → 流程、執行節點的 `trigger` → 判斷值、`p{n}` → 次要{n}；
  /// 其餘（變數名 x/a/b/c、輸出 out/true/false/bool）保持原樣。
  static String _localizedPortLabel(
      BuildContext context, BlockType type, String portId) {
    final l10n = AppLocalizations.of(context);
    return switch ((type, portId)) {
      (_, 'in') => l10n.portFlow,
      (BlockType.execute, 'trigger') => l10n.portJudgeValue,
      (BlockType.execute, final id) when id.startsWith('p') =>
        l10n.portSub(id.substring(1)),
      _ => portId,
    };
  }

  /// 各種語言的內建節點標籤，用於相容舊版資料（title 為內建標籤時視為未自訂）。
  static const List<String> _builtinLabels = [
    // 繁體中文
    '觸發', '讀取', '計數器', '判斷', '運算', '組合判斷', '執行',
    // 簡體中文
    '触发', '读取', '计数器', '判断', '运算', '组合判断', '执行',
    // 英文
    'Trigger', 'Read', 'Counter', 'Judge', 'Calc', 'Composite', 'Execute',
    // 日文
    'トリガー', '読み取り', 'カウンター', '判定', '計算', '組み合わせ判定', '実行',
  ];

  /// 取得節點顯示標題：未自訂（空或為內建標籤）時回傳在地化標籤，否則回傳自訂標題。
  static String _displayTitle(BuildContext context, FlowNode node) {
    final title = node.title.trim();
    if (title.isEmpty || _builtinLabels.contains(title)) {
      return _localizedBlockLabel(context, node.type);
    }
    return node.title;
  }

  /// 節點設定摘要條的地化文字（對應 models 層 [configSummary] 的 UI 呈現）。
  /// [nameOf] 可選回呼，將全域值 ID 轉換為顯示名稱。
  static String _localizedConfigSummary(BuildContext context, BlockType type,
      BlockConfig config,
      {String Function(int id)? nameOf}) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case BlockType.calc:
        return config.formula.isEmpty ? l10n.noFormula : config.formula;
      case BlockType.judge:
        final mode =
            config.judgeMode == 'range' ? l10n.rangeMode : l10n.singleMode;
        return '$mode ${config.judgeOperator}';
      case BlockType.composite:
        return config.logic;
      case BlockType.read:
        switch (config.sourceType) {
          case 'device_param':
            final sn = config.sourceSerial ?? '';
            final pid = config.sourcePollutantId?.toString() ?? '';
            return l10n.deviceParamSummary(sn, pid);
          case 'constant':
          case 'variable':
            final id = config.sourceGlobalValueId;
            final name = id != null ? (nameOf?.call(id) ?? '$id') : '—';
            return config.sourceType == 'constant'
                ? '${l10n.constant} $name'
                : '${l10n.variable} $name';
          default:
            return l10n.noSource;
        }
      case BlockType.trigger:
        switch (config.triggerType) {
          case 1:
            return l10n.deviceValue;
          case 2:
            return l10n.variableValue;
          case 3:
            return l10n.timeTrigger;
          default:
            return l10n.notConfigured;
        }
      case BlockType.counter:
        return config.countMode == 'increment'
            ? '${l10n.countIncrement} ${config.countValue}'
            : '${l10n.countDecrement} ${config.countValue}';
      case BlockType.execute:
        return l10n.actionsCount(config.actions.length);
    }
  }

  final FlowNode node;
  final FlowController controller;

  /// 畫布文字編輯退出回呼：節點內輸入框 Enter 提交／點擊節點體選取時呼叫
  /// （由編輯器交還畫布鍵盤焦點，使 Delete／Backspace 作用於選取物件）。
  final VoidCallback? onExitTextInput;

  /// 節點設定請求回呼（消費方提供節點型別 -> 設定對話框的對應邏輯）。
  final void Function(BuildContext context, String nodeId)? onConfigRequested;

  /// 節點內字型縮放係數（畫布工具列可調）。
  double get _fs => controller.fontScale;

  /// 「目前值／目前結果」行的高度（執行節點無輸出，不顯示該行），
  /// 埠／測試按鈕等縱向偏移用。
  double get _currentRowOffset =>
      node.type == BlockType.execute ? 0.0 : NodeMetrics.currentHeight(_fs);

  /// 埠標籤樣式（隨字型縮放）。
  TextStyle get _portLabelStyle =>
      TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 11 * _fs);

  @override
  Widget build(BuildContext context) {
    final color = builtinBlockTypeColor(node.type);
    final selected = controller.selectedNodeId == node.id;
    final hovered = controller.hoveredNodeId == node.id;
    final dragging = controller.draggingNodeId == node.id;

    // 邊框高亮優先級：拖曳 > 選取 > 懸停 > 預設。
    Color borderColor;
    double borderWidth;
    if (dragging) {
      borderColor = color;
      borderWidth = 3;
    } else if (selected) {
      borderColor = color;
      borderWidth = 2.5;
    } else if (hovered) {
      borderColor = color.withValues(alpha: 0.6);
      borderWidth = 2;
    } else {
      borderColor = Colors.black.withValues(alpha: 0.12);
      borderWidth = 1;
    }

    final screenPos = controller.worldToCanvas(node.position);
    final scale = controller.scale;
    final logicalW = NodeMetrics.width(_fs) + _deleteButtonOverflow;
    final logicalH = node.height(_fs) + _deleteButtonOverflow;

    return Positioned(
      left: screenPos.dx,
      top: screenPos.dy - _deleteButtonOverflow * scale,
      child: MouseRegion(
        onEnter: (_) => controller.setHoverNode(node.id),
        onExit: (_) => controller.setHoverNode(null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            controller.selectNode(node.id);
            onExitTextInput?.call();
          },
          onPanStart: (_) => controller.setDraggingNode(node.id),
          onPanEnd: (_) => controller.setDraggingNode(null),
          onPanCancel: () => controller.setDraggingNode(null),
          onPanUpdate: (d) => controller.moveNode(
            node.id,
            node.position + d.delta / controller.scale,
          ),
          onSecondaryTapUp: (d) {
            controller.selectNode(node.id);
            onExitTextInput?.call();
            _showContextMenu(context, d.globalPosition);
          },
          child: SizedBox(
            width: logicalW * scale,
            height: logicalH * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: logicalW,
                  height: logicalH,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 節點主體：向上／向右留出刪除按鈕的溢出空間。
                        Padding(
                          padding: const EdgeInsets.only(
                            top: _deleteButtonOverflow,
                            right: _deleteButtonOverflow,
                          ),
                          child: Container(
                            width: NodeMetrics.width(_fs),
                            height: node.height(_fs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                NodeMetrics.cornerRadius(_fs),
                              ),
                              border: Border.all(
                                color: borderColor,
                                width: borderWidth,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: dragging
                                      ? color.withValues(alpha: 0.35)
                                      : Colors.black26,
                                  blurRadius: dragging ? 10 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                NodeMetrics.cornerRadius(_fs) - 1,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildColorBar(color),
                                  _buildHeader(context, color),
                                  _buildConfigStrip(context, color),
                                  if (node.type != BlockType.execute)
                                    _buildCurrentResultRow(color),
                                  ..._buildPorts(context, color),
                                  _buildTestButton(context, color),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 刪除按鈕。
                        if (selected)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildDeleteButton(color),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context, Offset globalPos) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx,
        globalPos.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'config',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).config),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).delete),
            ],
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    if (result == 'config') {
      _openConfig(context);
    } else if (result == 'delete') {
      controller.removeNode(node.id);
    }
  }

  void _openConfig(BuildContext context) {
    if (onConfigRequested != null) {
      onConfigRequested!(context, node.id);
    } else {
      _openDefaultConfigDialog(context);
    }
  }

  Future<void> _openDefaultConfigDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DefaultConfigDialog(node: node, controller: controller),
    );
  }

  Widget _buildColorBar(Color color) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: 6,
      child: ColoredBox(color: color),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    return Positioned(
      left: 14,
      right: 10,
      top: 4,
      height: NodeMetrics.headerHeight(_fs) - 6,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _displayTitle(context, node),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * _fs,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _localizedDescription(context, node.type),
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.45),
                    fontSize: 11 * _fs,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.selectNode(node.id);
              _openConfig(context);
            },
            child: Tooltip(
              message: AppLocalizations.of(context).config,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings_outlined, size: 14, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigStrip(BuildContext context, Color color) {
    final content = Container(
      padding: const EdgeInsets.only(left: 14, right: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _localizedConfigSummary(context, node.type, node.config),
              style: TextStyle(
                fontSize: 11 * _fs,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
    return Positioned(
      left: 0,
      right: 0,
      top: NodeMetrics.headerHeight(_fs),
      height: NodeMetrics.configHeight(_fs),
      child: _ConfigStrip(
        color: color,
        onTap: () {
          controller.selectNode(node.id);
          _openConfig(context);
        },
        child: content,
      ),
    );
  }

  Widget _buildCurrentResultRow(Color color) {
    return Positioned(
      left: 0,
      right: 0,
      top: NodeMetrics.headerHeight(_fs) + NodeMetrics.configHeight(_fs),
      height: NodeMetrics.currentHeight(_fs),
      child: _CurrentResultRow(
        node: node,
        controller: controller,
        color: color,
      ),
    );
  }

  Widget _buildDeleteButton(Color color) {
    return GestureDetector(
      onTap: () => controller.removeNode(node.id),
      child: Container(
        width: _deleteButtonSize,
        height: _deleteButtonSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.close, size: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildTestButton(BuildContext context, Color color) {
    final rows = node.inputs.length > node.outputs.length
        ? node.inputs.length
        : node.outputs.length;
    final midY =
        NodeMetrics.headerHeight(_fs) +
        NodeMetrics.configHeight(_fs) +
        _currentRowOffset +
        rows * NodeMetrics.rowHeight(_fs) / 2;
    return Positioned(
      left: NodeMetrics.width(_fs) / 2 + 13,
      top: midY - 13,
      child: Tooltip(
        message: AppLocalizations.of(context).testBlock,
        child: GestureDetector(
          onTap: () => _testBlock(context),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.science_outlined, size: 14, color: color),
          ),
        ),
      ),
    );
  }

  void _testBlock(BuildContext context) {
    final result = controller.testBlock(node.id);
    BlockTestToast.show(context, _buildTestToastContent(context, result));
  }

  Widget _buildTestToastContent(BuildContext context, BlockTestResult result) {
    final color = builtinBlockTypeColor(node.type);
    final copyText = _blockTestCopyText(context, result);
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.science_outlined, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).testBlockTitle(_displayTitle(context, node)),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: AppLocalizations.of(context).copyResultWithInputs,
                    icon: const Icon(Icons.copy, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context).copied),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: AppLocalizations.of(context).close,
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: BlockTestToast.hide,
                  ),
                ],
              ),
              const Divider(height: 10),
              _resultLine(AppLocalizations.of(context).output, result.outputText,
                  emphasize: true),
              for (final n in result.notes)
                _resultLine(AppLocalizations.of(context).note, n),
              for (final e in result.errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 14,
                        color: Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (result.sources.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final s in result.sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).failureSource,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _blockTestCopyText(BuildContext context, BlockTestResult result) {
    final l10n = AppLocalizations.of(context);
    final buf = StringBuffer()
      ..writeln(l10n.testBlockTitle(_displayTitle(context, node)))
      ..writeln('${l10n.output}：${result.outputText}');
    if (result.notes.isNotEmpty) {
      buf.writeln('${l10n.note}：');
      for (final n in result.notes) {
        buf.writeln('  · $n');
      }
    }
    if (result.errors.isNotEmpty) {
      buf.writeln('${l10n.error}：');
      for (final e in result.errors) {
        buf.writeln('  · $e');
      }
    }
    if (result.sources.isNotEmpty) {
      buf.writeln('${l10n.failureSource}：');
      for (final s in result.sources) {
        buf.writeln('  · $s');
      }
    }
    return buf.toString();
  }

  Widget _resultLine(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '$label：',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: emphasize ? 15 : 12,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                color: emphasize ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _portHasInputBox(FlowNode node, String portId) {
    switch (node.type) {
      case BlockType.calc:
        return true;
      case BlockType.judge:
        return portId != 'x';
      default:
        return false;
    }
  }

  List<Widget> _buildPorts(BuildContext context, Color color) {
    final widgets = <Widget>[];
    final r = NodeMetrics.portRadius(_fs);
    final inset = NodeMetrics.portInset(_fs);

    for (var i = 0; i < node.inputs.length; i++) {
      final port = node.inputs[i];
      final y =
          NodeMetrics.headerHeight(_fs) +
          NodeMetrics.configHeight(_fs) +
          _currentRowOffset +
          i * NodeMetrics.rowHeight(_fs) +
          NodeMetrics.rowHeight(_fs) / 2;
      widgets.add(
        Positioned(
          left: inset - r,
          top: y - r,
          child: PortWidget(
            nodeId: node.id,
            port: port,
            controller: controller,
            color: color,
            isTarget:
                controller.draftTargetNodeId == node.id &&
                controller.draftTargetPortId == port.id,
          ),
        ),
      );
      if (isDynamicInputType(node.type)) {
        final hasBox = _portHasInputBox(node, port.id);
        final showInput =
            !hasBox || !controller.shouldHideInputBox(node.id, port.id);
        widgets.add(
          Positioned(
            left: inset + r + 4,
            top: y - 11,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_localizedPortLabel(context, node.type, port.id),
                    style: _portLabelStyle),
                if (hasBox) ...[
                  const SizedBox(width: 6),
                  if (showInput)
                    _CalcInputField(
                      controller: controller,
                      nodeId: node.id,
                      portId: port.id,
                      initialValue: node.config.inputValues[port.id] ?? '',
                      onExitTextInput: onExitTextInput,
                    )
                  else
                    Text(
                      AppLocalizations.of(context).connected,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Positioned(
            left: inset + r + 4,
            top: y - 9,
            child: Text(_localizedPortLabel(context, node.type, port.id),
                style: _portLabelStyle),
          ),
        );
      }
    }

    // 動態入口節點：未展開到上限時，末尾渲染「新增點」。
    if (isDynamicInputType(node.type) &&
        node.inputs.length < maxDynamicInputs(node.type)) {
      final addY =
          NodeMetrics.headerHeight(_fs) +
          NodeMetrics.configHeight(_fs) +
          _currentRowOffset +
          node.inputs.length * NodeMetrics.rowHeight(_fs) +
          NodeMetrics.rowHeight(_fs) / 2;
      final addTarget =
          controller.draftTargetNodeId == node.id &&
          controller.draftTargetPortId == addPointPortId;
      widgets.add(
        Positioned(
          left: inset - r - 4,
          top: addY - r - 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              controller.selectNode(node.id);
              controller.addDynamicInput(node.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Tooltip(
                message: AppLocalizations.of(context).addInputPortHint,
                child: AnimatedScale(
                  scale: addTarget ? 1.35 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    width: NodeMetrics.portRadius(_fs) * 2,
                    height: NodeMetrics.portRadius(_fs) * 2,
                    decoration: BoxDecoration(
                      color: addTarget
                          ? color.withValues(alpha: 0.15)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: addTarget ? Colors.white : color,
                        width: addTarget ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: addTarget
                              ? color.withValues(alpha: 0.55)
                              : Colors.black26,
                          blurRadius: addTarget ? 8 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      size: 10,
                      color: addTarget ? Colors.white : color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < node.outputs.length; i++) {
      final port = node.outputs[i];
      final y =
          NodeMetrics.headerHeight(_fs) +
          NodeMetrics.configHeight(_fs) +
          _currentRowOffset +
          i * NodeMetrics.rowHeight(_fs) +
          NodeMetrics.rowHeight(_fs) / 2;
      widgets.add(
        Positioned(
          left: NodeMetrics.width(_fs) - inset - r,
          top: y - r,
          child: PortWidget(
            nodeId: node.id,
            port: port,
            controller: controller,
            color: color,
            onTap: () {
              controller.selectNode(node.id);
              _openConfig(context);
            },
          ),
        ),
      );
      widgets.add(
        Positioned(
          right: inset + r + 4,
          top: y - 9,
          child: Text(
            _localizedPortLabel(context, node.type, port.id),
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: 11 * _fs,
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// 「目前值／目前結果」行：展示節點的目前求值結果。
class _CurrentResultRow extends StatefulWidget {
  const _CurrentResultRow({
    required this.node,
    required this.controller,
    required this.color,
  });

  final FlowNode node;
  final FlowController controller;
  final Color color;

  @override
  State<_CurrentResultRow> createState() => _CurrentResultRowState();
}

class _CurrentResultRowState extends State<_CurrentResultRow> {
  DateTime? _lastRefreshAt;
  int _remaining = 0;
  Timer? _cooldownTimer;

  FlowController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.globalValues.addListener(_onChanged);
    controller.deviceProvider?.addListener(_onChanged);
  }

  @override
  void dispose() {
    controller.globalValues.removeListener(_onChanged);
    controller.deviceProvider?.removeListener(_onChanged);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _refresh() {
    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastRefreshAt = now;
    _remaining = 10;
    _startCooldownTick();
    setState(() {});
  }

  void _startCooldownTick() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _remaining = 0;
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final fs = controller.fontScale;
    final cfg = widget.node.config;
    final isRead = widget.node.type == BlockType.read;
    final isDeviceParam = isRead && cfg.sourceType == 'device_param';

    final value = controller.currentBlockResult(widget.node.id);
    final valueText = value == null ? '—' : formatTestValue(value);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              isRead
                  ? AppLocalizations.of(context).currentValue
                  : AppLocalizations.of(context).currentResult,
              style: TextStyle(
                fontSize: 11 * fs,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              valueText,
              style: TextStyle(
                fontSize: 11 * fs,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDeviceParam)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildRefreshButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    final fs = controller.fontScale;
    final cooling = _remaining > 0;
    final btnSize = 22 * fs.clamp(1.0, 1.4);
    return Tooltip(
      message: cooling
          ? AppLocalizations.of(context).refreshCooldown(_remaining)
          : AppLocalizations.of(context).refreshIdle,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: cooling ? null : _refresh,
        child: SizedBox(
          width: btnSize,
          height: btnSize,
          child: cooling
              ? Center(
                  child: Text(
                    '$_remaining',
                    style: TextStyle(
                      fontSize: 10 * fs,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38,
                    ),
                  ),
                )
              : Icon(
                  Icons.refresh,
                  size: 14 * fs,
                  color: widget.color.withValues(alpha: 0.8),
                ),
        ),
      ),
    );
  }
}

/// 運算節點埠上的內聯輸入框（節點中帶有的輸入框）：
/// 為 x / a~i 直接填寫數字作為輸入值；埠已連線時以 from 傳值為準，此值為備用。
class _CalcInputField extends StatefulWidget {
  const _CalcInputField({
    required this.controller,
    required this.nodeId,
    required this.portId,
    required this.initialValue,
    this.onExitTextInput,
  });

  final FlowController controller;
  final String nodeId;
  final String portId;
  final String initialValue;
  final VoidCallback? onExitTextInput;

  @override
  State<_CalcInputField> createState() => _CalcInputFieldState();
}

class _CalcInputFieldState extends State<_CalcInputField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.controller.fontScale;
    return SizedBox(
      width: (72 * fs).clamp(72.0, 120.0),
      height: 22,
      child: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => widget.onExitTextInput?.call(),
        onTapOutside: (_) {},
        style: TextStyle(fontSize: 11 * fs),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
          ),
          hintText: AppLocalizations.of(context).value,
        ),
        onChanged: (v) =>
            widget.controller.updateInputValue(widget.nodeId, widget.portId, v),
      ),
    );
  }
}

/// 設定摘要條：點擊開啟節點設定（懸停時高亮提示可點擊）。
class _ConfigStrip extends StatefulWidget {
  const _ConfigStrip({
    required this.color,
    required this.child,
    required this.onTap,
  });

  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ConfigStrip> createState() => _ConfigStripState();
}

class _ConfigStripState extends State<_ConfigStrip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: _hover ? widget.color.withValues(alpha: 0.10) : null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 預設節點設定對話框（當消費方未提供 [onConfigRequested] 時使用）。
class _DefaultConfigDialog extends StatelessWidget {
  const _DefaultConfigDialog({required this.node, required this.controller});

  final FlowNode node;
  final FlowController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).nodeTitleConfig(node.title)),
      content: SizedBox(
        width: 400,
        child: _buildContent(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).close),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (node.type) {
      case BlockType.calc:
        return TextField(
          controller: TextEditingController(text: node.config.formula),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).calculationFormula,
            hintText: AppLocalizations.of(context).formulaHint,
          ),
          onChanged: (v) {
            node.config.formula = v;
            controller.updateNodeConfig(node.id, node.config);
          },
        );
      case BlockType.judge:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: node.config.judgeMode,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).judgeMode),
              items: [
                DropdownMenuItem(
                    value: 'range',
                    child: Text(AppLocalizations.of(context).rangeMode)),
                DropdownMenuItem(
                    value: 'single',
                    child: Text(AppLocalizations.of(context).singleMode)),
              ],
              onChanged: (v) {
                if (v == null) return;
                node.config.judgeMode = v;
                controller.updateNodeConfig(node.id, node.config);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: node.config.judgeOperator,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).judgeOperator),
              items: [
                for (final o in node.config.judgeMode == 'range'
                    ? BlockConfig.rangeOperators
                    : BlockConfig.singleOperators)
                  DropdownMenuItem(value: o, child: Text(o)),
              ],
              onChanged: (v) {
                if (v == null) return;
                node.config.judgeOperator = v;
                controller.updateNodeConfig(node.id, node.config);
              },
            ),
          ],
        );
      case BlockType.composite:
        return DropdownButtonFormField<String>(
          initialValue: node.config.logic,
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context).compositeLogic),
          items: const [
            DropdownMenuItem(value: 'AND', child: Text('AND')),
            DropdownMenuItem(value: 'OR', child: Text('OR')),
            DropdownMenuItem(value: 'NOT', child: Text('NOT')),
          ],
          onChanged: (v) {
            if (v == null) return;
            node.config.logic = v;
            controller.updateNodeConfig(node.id, node.config);
          },
        );
      default:
        // 其他節點型別無自訂配置，僅顯示節點標題作為提示。
        return Text(
          AppLocalizations.of(context).nodeTitleConfig(node.title),
          style: const TextStyle(color: Colors.black54),
        );
    }
  }
}