import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// 세션 만료(Refresh 실패) 시 호출되는 콜백 타입이다.
typedef OnSessionExpiredCallback = Future<void> Function();

/// 모든 API 요청에 JWT Bearer 토큰을 주입하고, 401 응답 시 Refresh Token 재발급을 직렬화하는 인터셉터이다.
class AuthInterceptor extends QueuedInterceptor {
  /// [AuthInterceptor] 인스턴스를 생성한다.
  AuthInterceptor({
    required this._tokenStorage,
    required this._refreshDio,
    required this._retryDio,
    required this._onSessionExpired,
  });

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final Dio _retryDio;
  final OnSessionExpiredCallback _onSessionExpired;

  /// 동시 다발적인 401 응답 시 중복 Refresh Rotation 요청을 방지하기 위한 공유 Future
  Completer<String?>? _refreshCompleter;

  static const _retriedKey = '_auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Client-Type'] = 'mobile';

    // 로그인·토큰갱신 요청에는 기존 만료 토큰을 실어 보내지 않는다.
    if (!_isAuthPublicEndpoint(options.path)) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;
    final alreadyRetried = requestOptions.extra[_retriedKey] == true;

    if (statusCode != 401 ||
        alreadyRetried ||
        _isAuthPublicEndpoint(requestOptions.path)) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null || newAccessToken.isEmpty) {
      await _onSessionExpired();
      handler.next(err);
      return;
    }

    // 새 토큰으로 원 요청을 1회 재시도한다.
    final updatedOptions = requestOptions.copyWith(
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
        'X-Client-Type': 'mobile',
      },
      extra: {
        ...requestOptions.extra,
        _retriedKey: true,
      },
    );

    try {
      final response = await _retryDio.fetch<dynamic>(updatedOptions);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        return completer.future;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'X-Client-Type': 'mobile'}),
      );

      final data = response.data;
      final newAccess = data?['access_token'] as String?;
      final newRefresh = data?['refresh_token'] as String?;

      if (newAccess != null &&
          newAccess.isNotEmpty &&
          newRefresh != null &&
          newRefresh.isNotEmpty) {
        await _tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        completer.complete(newAccess);
      } else {
        completer.complete(null);
      }
    } catch (_) {
      completer.complete(null);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  bool _isAuthPublicEndpoint(String path) {
    return path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/google-login') ||
        path.contains('/api/v1/auth/refresh');
  }
}
