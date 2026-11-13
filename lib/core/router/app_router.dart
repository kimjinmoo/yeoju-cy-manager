import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/unauthorized_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/license_keys/presentation/pages/manager_home_page.dart';

/// 앱 내 라우트 경로 상수 정의이다.
abstract final class AppRoutes {
  /// 초기 세션 확인 스플래시 경로
  static const splash = '/splash';

  /// 로그인 경로
  static const login = '/login';

  /// 관리자 권한 없음 안내 경로
  static const unauthorized = '/unauthorized';

  /// 시디키·간편서명 관리 메인 경로
  static const home = '/';
}

/// [AuthState] 변화를 [GoRouter.refreshListenable]로 전달하는 브릿지이다.
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }
}

/// 인증 상태 기반 리다이렉트 가드가 포함된 전역 [GoRouter] Provider이다.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;

      switch (authState.status) {
        case AuthStatus.initializing:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          return location == AppRoutes.login ? null : AppRoutes.login;
        case AuthStatus.forbidden:
          return location == AppRoutes.unauthorized
              ? null
              : AppRoutes.unauthorized;
        case AuthStatus.authenticated:
          if (location == AppRoutes.splash ||
              location == AppRoutes.login ||
              location == AppRoutes.unauthorized) {
            return AppRoutes.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) => const UnauthorizedPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ManagerHomePage(),
      ),
    ],
  );
});
