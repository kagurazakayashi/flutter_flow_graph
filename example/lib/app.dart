import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_flow_graph/flutter_flow_graph.dart';


/// Flutter Flow Graph 範例應用。
class FlowGraphExampleApp extends StatelessWidget {
  const FlowGraphExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Flow Graph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FlowGraphExamplePage(),
    );
  }
}

/// 範例頁面：展示一個具備左側面板的完整節點圖編輯器。
class FlowGraphExamplePage extends StatefulWidget {
  const FlowGraphExamplePage({super.key});

  @override
  State<FlowGraphExamplePage> createState() => _FlowGraphExamplePageState();
}

class _FlowGraphExamplePageState extends State<FlowGraphExamplePage> {
  final FlowController _controller = FlowController();
  final EditorSettings _settings = EditorSettings();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Flow Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: '重設視口',
            onPressed: _controller.resetView,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: '放大',
            onPressed: () {
              _controller.zoomAt(1.2, Offset.zero);
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: '縮小',
            onPressed: () {
              _controller.zoomAt(1 / 1.2, Offset.zero);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 左側節點面板。
          SizedBox(
            width: 180,
            child: BlockPalette(
              onAddBlock: (type) => _controller.addNode(type, Offset.zero),
              customBlockTypes: _customBlockTypes(),
            ),
          ),
          const VerticalDivider(width: 1),
          // 畫布區域。
          Expanded(
            child: NodeCanvas(
              controller: _controller,
              settings: _settings,
              onExitTextInput: () => FocusScope.of(context).unfocus(),
              onNodeConfigRequested: _onNodeConfigRequested,
            ),
          ),
        ],
      ),
    );
  }

  /// 自訂節點型別（範例預設為空，消費方可擴充）。
  List<CustomPaletteBlockType> _customBlockTypes() {
    return const [];
  }

  /// 節點設定請求回呼。
  void _onNodeConfigRequested(BuildContext context, String nodeId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('節點 $nodeId：設定功能由消費方提供'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}