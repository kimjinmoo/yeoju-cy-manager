import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// 세션 만료 시 UI/인증 상태를 초기화하기 위한 전역 이벤트 핸들러 Provider이다.
///
/// 순환 참조(AuthNotifier <-> Dio)를 방지하기 위해 콜백 레퍼런스로 연결한다.
final sessionExpiredCallbackProvider =
    Provider<SessionExpiredDispatcher>((ref) => SessionExpiredDispatcher());

/// 세션 만료 콜백을 보관하고 실행하는 경량 디스패처이다.
class SessionExpiredDispatcher {
  Future<void> Function()? _listener;

  /// 세션 만료 리스너를 등록한다.
  void register(Future<void> Function() listener) {
    _listener = listener;
  }

  /// 등록된 세션 만료 리스너를 실행한다.
  Future<void> dispatch() async {
    final fn = _listener;
    if (fn != null) {
      await fn();
    }
  }
}

/// 앱 전역 API 통신용 [Dio] 인스턴스를 제공하는 Riverpod Provider이다.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final sessionDispatcher = ref.watch(sessionExpiredCallbackProvider);

  final baseOptions = BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 15),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Type': 'mobile',
    },
  );

  final dio = Dio(baseOptions);
  final auxDio = Dio(baseOptions);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: auxDio,
      retryDio: auxDio,
      onSessionExpired: () async {
        await tokenStorage.clearTokens();
        await sessionDispatcher.dispatch();
      },
    ),
  );

  return dio;
});
