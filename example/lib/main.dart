/// 範例應用入口點。
library;

import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlowGraphExampleApp());
}