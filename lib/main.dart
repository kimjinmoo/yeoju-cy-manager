import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeoju_cy_manager/app.dart';

/// 여주자전거여행 키 관리 앱의 진입점입니다.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: YeojuCycleManagerApp()));
}
