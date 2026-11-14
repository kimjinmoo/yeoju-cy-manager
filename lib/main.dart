import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeoju_cy_manager/app.dart';
import 'package:yeoju_cy_manager/core/analytics/analytics_service.dart';

/// 여주자전거여행 키 관리 앱의 진입점입니다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final analytics = await FirebaseAppAnalytics.initialize();
  runApp(
    ProviderScope(
      overrides: [
        appAnalyticsProvider.overrideWithValue(analytics),
      ],
      child: const YeojuCycleManagerApp(),
    ),
  );
}
