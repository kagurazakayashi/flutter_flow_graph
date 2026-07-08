import 'package:flutter/material.dart';

import '../models/flow_node.dart';

/// 左側節點面板，展示所有可新增的節點型別。
/// 支援點擊新增（到畫布中心）與拖曳進入畫布。
class BlockPalette extends StatelessWidget {
  const BlockPalette({
    super.key,
    required this.onAddBlock,
    this.fontScale = 1.0,
    this.hintText = '點擊或拖曳到畫布',
    this.customBlockTypes = const [],
  });

  final ValueChanged<BlockType> onAddBlock;

  /// 節點內字型縮放（用於拖曳預覽尺寸與畫布節點一致）。
  final double fontScale;

  /// 使用提示文字。
  final String hintText;

  /// 自訂節點型別列表（消費方可注入額外的節點型別）。
  final List<CustomPaletteBlockType> customBlockTypes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFFF5F6F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
            child: Text(
              hintText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                // 內建節點型別
                for (final type in BlockType.values)
                  _BlockItem(
                    type: type,
                    fontScale: fontScale,
                    onTap: () => onAddBlock(type),
                  ),
                // 自訂節點型別
                for (final custom in customBlockTypes)
                  _CustomBlockItem(
                    blockType: custom,
                    fontScale: fontScale,
                    onTap: () => custom.onTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 自訂面板節點型別描述。
/// 消費方可透過此類別在面板中展示自訂節點。
class CustomPaletteBlockType {
  const CustomPaletteBlockType({
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
}

class _BlockItem extends StatelessWidget {
  const _BlockItem({
    required this.type,
    required this.fontScale,
    required this.onTap,
  });

  final BlockType type;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Draggable<BlockType>(
      data: type,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: Offset(
          -NodeMetrics.width(fontScale) / 2,
          -NodeMetrics.headerHeight(fontScale) / 2,
        ),
        child: _BlockDragPreview(
          label: builtinBlockTypeLabel(type),
          color: builtinBlockTypeColor(type),
          fontScale: fontScale,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildCard(
          label: builtinBlockTypeLabel(type),
          description: builtinBlockTypeDescription(type),
          color: builtinBlockTypeColor(type),
        ),
      ),
      child: _buildCard(
        label: builtinBlockTypeLabel(type),
        description: builtinBlockTypeDescription(type),
        color: builtinBlockTypeColor(type),
      ),
    );
  }

  Widget _buildCard({
    required String label,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 14,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomBlockItem extends StatelessWidget {
  const _CustomBlockItem({
    required this.blockType,
    required this.fontScale,
    required this.onTap,
  });

  final CustomPaletteBlockType blockType;
  final double fontScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 14,
                height: 40,
                decoration: BoxDecoration(
                  color: blockType.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      blockType.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blockType.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 拖曳時的節點預覽樣式。
class _BlockDragPreview extends StatelessWidget {
  const _BlockDragPreview({
    required this.label,
    required this.color,
    required this.fontScale,
  });

  final String label;
  final Color color;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: NodeMetrics.width(fontScale),
        height: NodeMetrics.headerHeight(fontScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            NodeMetrics.cornerRadius(fontScale),
          ),
          border: Border.all(color: color, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            NodeMetrics.cornerRadius(fontScale) - 2,
          ),
          child: Row(
            children: [
              Container(width: 6, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}