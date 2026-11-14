import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/auth_user.dart';

/// 앱 전역 인증 흐름(자동 로그인, ID/PW 로그인, Google 로그인, 로그아웃)을 관리하는 Notifier이다.
class AuthNotifier extends Notifier<AuthState> {
  bool _initialized = false;

  @override
  AuthState build() {
    ref.read(sessionExpiredCallbackProvider).register(_handleSessionExpired);

    if (!_initialized) {
      _initialized = true;
      Future.microtask(_bootstrapSession);
    }

    return const AuthState.initial();
  }

  Future<void> _bootstrapSession() async {
    final minDuration = ref.read(splashMinDurationProvider);
    await _restoreSavedServerPreference();
    final repo = ref.read(authRepositoryProvider);
    // 스플래시 브랜드 애니메이션이 지나치게 빠르게 사라지지 않도록 최소 노출 시간을 보장한다.
    final results = await Future.wait<dynamic>([
      repo.restoreSession(),
      if (minDuration > Duration.zero) Future<void>.delayed(minDuration),
    ]);
    final user = results.first as AuthUser?;
    _applyAuthenticatedUser(user);
  }

  Future<void> _restoreSavedServerPreference() async {
    try {
      final storage = ref.read(tokenStorageProvider);
      final savedCustomUrl = await storage.getSavedCustomUrl();
      final savedEnvId = await storage.getSavedEnvId();
      final configNotifier = ref.read(appConfigProvider.notifier);

      if (savedCustomUrl != null && savedCustomUrl.isNotEmpty) {
        configNotifier.setCustomApiBaseUrl(savedCustomUrl);
      } else if (savedEnvId != null && savedEnvId.isNotEmpty) {
        configNotifier.selectEnvironment(ServerEnvironment.fromId(savedEnvId));
      }
    } catch (_) {
      // 저장된 환경 설정 복원 실패 시 기본 설정을 유지한다.
    }
  }

  /// 이메일과 비밀번호로 로그인한다.
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).loginWithEmail(
            email: email,
            password: password,
          );
      _applyAuthenticatedUser(user);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        status: AuthStatus.unauthenticated,
        errorMessage: extractErrorMessage(error, fallback: '로그인에 실패했습니다.'),
      );
      return false;
    }
  }

  /// Google 계정으로 로그인한다.
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).loginWithGoogle();
      if (user == null) {
        state = state.copyWith(isSubmitting: false);
        return false;
      }
      _applyAuthenticatedUser(user);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        status: AuthStatus.unauthenticated,
        errorMessage: extractErrorMessage(error, fallback: 'Google 로그인에 실패했습니다.'),
      );
      return false;
    }
  }

  /// 로그아웃을 수행하고 로그인 화면으로 전환한다.
  Future<void> logout() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 서버 환경 프리셋을 변경하고 저장한다.
  Future<void> switchServerEnvironment(ServerEnvironment env) async {
    ref.read(appConfigProvider.notifier).selectEnvironment(env);
    await ref.read(tokenStorageProvider).saveServerPreference(envId: env.id);
  }

  /// 사용자 지정 서버 URL을 변경하고 저장한다.
  Future<void> setCustomServerUrl(String url) async {
    ref.read(appConfigProvider.notifier).setCustomApiBaseUrl(url);
    final updated = ref.read(appConfigProvider);
    await ref.read(tokenStorageProvider).saveServerPreference(
          envId: updated.environment.id,
          customUrl: updated.apiBaseUrl,
        );
  }

  /// 에러 배너 메시지를 초기화한다.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _applyAuthenticatedUser(AuthUser? user) {
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    if (!user.hasCycleAdminRole) {
      state = AuthState(
        status: AuthStatus.forbidden,
        user: user,
      );
      return;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  Future<void> _handleSessionExpired() async {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: '로그인 세션이 만료되었습니다. 다시 로그인해주세요.',
    );
  }
}

/// 스플래시 화면 최소 표시 시간 Provider이다.
///
/// 앱 초기 구동 시 브랜드 모션이 자연스럽게 보이도록 기본 1.6초를 유지하며,
/// 위젯 테스트에서 필요 시 오버라이드할 수 있다.
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1600),
);

/// 앱 전역 인증 상태를 제공하는 Riverpod Provider이다.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
