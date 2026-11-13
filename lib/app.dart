import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 여주자전거여행 통합 키 관리 앱 루트 위젯이다.
class YeojuCycleManagerApp extends ConsumerWidget {
  /// [YeojuCycleManagerApp] 위젯을 생성한다.
  const YeojuCycleManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '여주자전거여행-관리자',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
