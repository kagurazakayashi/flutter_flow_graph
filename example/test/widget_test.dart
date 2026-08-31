// 範例應用冒煙測試（Smoke Test）。
//
// 此測試僅驗證範例應用可以正常建構，不進行深度互動。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/app.dart';

void main() {
  testWidgets('範例應用可以正常建構', (WidgetTester tester) async {
    // 建構應用並觸發一幀。
    await tester.pumpWidget(const FlowGraphExampleApp());
    await tester.pump();

    // 驗證畫布已出現（尋找「重置視口」按鈕的圖示）。
    expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
  });
}
