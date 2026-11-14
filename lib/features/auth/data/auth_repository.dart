import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sandbox/review_sandbox.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';

/// 로그인·토큰 갱신·내 정보 조회·로그아웃을 담당하는 인증 저장소 인터페이스이다.
abstract class AuthRepository {
  /// 이메일/비밀번호로 로그인하고 사용자 정보를 반환한다.
  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
  });

  /// Google 네이티브 로그인으로 ID 토큰을 획득해 서버 인증을 수행한다.
  Future<AuthUser?> loginWithGoogle();

  /// 저장된 토큰을 이용해 현재 사용자 정보를 조회한다.
  Future<AuthUser?> restoreSession();

  /// 서버 로그아웃 및 로컬 토큰·Google 세션을 정리한다.
  Future<void> logout();
}

/// `grepiu_server`의 `/api/v1/auth/**` API 및 Google Sign-In과 연동하는 [AuthRepository] 구현체이다.
class GrepiuAuthRepository implements AuthRepository {
  /// [GrepiuAuthRepository] 인스턴스를 생성한다.
  GrepiuAuthRepository({
    required this._dio,
    required this._tokenStorage,
    required this._config,
  });

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AppConfig _config;

  static Future<void>? _googleInitFuture;

  @override
  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
        options: Options(headers: {'X-Client-Type': 'mobile'}),
      );

      final tokens = _extractTokens(response.data);
      await _tokenStorage.saveTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );

      return await fetchMe();
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallback: '이메일 또는 비밀번호를 확인해주세요.',
      );
    }
  }

  @override
  Future<AuthUser?> loginWithGoogle() async {
    try {
      final signIn = GoogleSignIn.instance;
      if (!signIn.supportsAuthenticate()) {
        throw const ApiException(
          message: '현재 실행 환경에서는 Google 네이티브 로그인을 지원하지 않습니다. 이메일 로그인을 이용해주세요.',
        );
      }

      // google_sign_in v7 규격상 initialize는 앱 생명주기 내 단 1회만 호출해야 한다.
      _googleInitFuture ??= signIn.initialize(
        serverClientId: _config.googleServerClientId,
      );
      await _googleInitFuture;

      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          message: 'Google 인증 토큰(idToken)을 가져오지 못했습니다. OAuth 클라이언트 설정을 확인해주세요.',
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/google-login',
        data: {'idToken': idToken},
        options: Options(headers: {'X-Client-Type': 'mobile'}),
      );

      final tokens = _extractTokens(response.data);
      await _tokenStorage.saveTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );

      return await fetchMe();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        // 사용자가 직접 로그인 창을 닫은 경우 오류 대신 취소 처리한다.
        return null;
      }
      final detail = e.description != null && e.description!.trim().isNotEmpty
          ? ' (${e.code.name}: ${e.description})'
          : ' (${e.code.name})';
      throw ApiException(
        message: 'Google 로그인에 실패했습니다.$detail',
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallback: 'Google 계정 인증에 실패했습니다.',
      );
    }
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final accessToken = await _tokenStorage.getAccessToken();
    final refreshToken = await _tokenStorage.getRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }

    try {
      return await fetchMe();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _tokenStorage.clearTokens();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 현재 로그인된 사용자 정보(`/api/v1/auth/me`)를 조회한다.
  Future<AuthUser> fetchMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/auth/me');
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: '사용자 정보를 불러올 수 없습니다.');
      }
      return AuthUser.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallback: '사용자 정보를 확인하지 못했습니다.',
      );
    }
  }

  @override
  Future<void> logout() async {
    String? token;
    try {
      token = await _tokenStorage.getAccessToken();
    } catch (_) {
      token = null;
    }

    // 로컬 토큰을 먼저 제거하고, 서버 세션 해제와 Google SDK 정리는 병렬로 짧게 대기한다.
    await _tokenStorage.clearTokens();
    await Future.wait<void>([
      _revokeServerSession(token),
      _signOutGoogleSdk(),
    ]);
  }

  /// 서버 로그아웃 엔드포인트를 호출한다. 지연 시에도 UI 전환이 막히지 않도록 짧은 타임아웃을 사용한다.
  Future<void> _revokeServerSession(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _dio.post<dynamic>(
        '/api/v1/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // 만료된 토큰이거나 네트워크 지연/오류가 발생해도 로그아웃을 계속 진행한다.
    }
  }

  /// Google SDK 인증 세션을 정리한다. 기기 Credential Manager(Samsung Pass 등) 응답 지연에 대비해 제한 시간을 둔다.
  Future<void> _signOutGoogleSdk() async {
    if (_googleInitFuture == null) return;
    try {
      await GoogleSignIn.instance.signOut().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      // Google SDK signOut 실패 또는 타임아웃은 무시한다.
    }
  }

  (String, String) _extractTokens(Map<String, dynamic>? data) {
    final accessToken = data?['access_token'] as String?;
    final refreshToken = data?['refresh_token'] as String?;
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw const ApiException(message: '서버로부터 유효한 인증 토큰을 받지 못했습니다.');
    }
    return (accessToken, refreshToken);
  }
}

/// 스토어 심사 테스트 계정(`test`)과 실서버 인증(`GrepiuAuthRepository`)을 분리 처리하는 [AuthRepository] 래퍼이다.
class SandboxAwareAuthRepository implements AuthRepository {
  /// [SandboxAwareAuthRepository] 인스턴스를 생성한다.
  SandboxAwareAuthRepository({
    required this._delegate,
    required this._tokenStorage,
    required this._sandboxStore,
    required this._onSandboxChanged,
  });

  final AuthRepository _delegate;
  final TokenStorage _tokenStorage;
  final ReviewSandboxStore _sandboxStore;
  final void Function(bool enabled) _onSandboxChanged;

  @override
  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (ReviewSandboxConfig.isReviewId(email)) {
      if (!ReviewSandboxConfig.isReviewCredentials(
        id: email,
        password: password,
      )) {
        throw const ApiException(
          message: '아이디 또는 비밀번호가 올바르지 않습니다.',
          statusCode: 401,
        );
      }
      _sandboxStore.reset();
      await _tokenStorage.saveTokens(
        accessToken: ReviewSandboxConfig.sandboxAccessToken,
        refreshToken: ReviewSandboxConfig.sandboxRefreshToken,
      );
      _onSandboxChanged(true);
      return ReviewSandboxConfig.reviewUser;
    }

    _onSandboxChanged(false);
    return _delegate.loginWithEmail(email: email, password: password);
  }

  @override
  Future<AuthUser?> loginWithGoogle() async {
    _onSandboxChanged(false);
    return _delegate.loginWithGoogle();
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (ReviewSandboxConfig.isSandboxToken(accessToken)) {
      _sandboxStore.reset();
      _onSandboxChanged(true);
      return ReviewSandboxConfig.reviewUser;
    }
    _onSandboxChanged(false);
    return _delegate.restoreSession();
  }

  @override
  Future<void> logout() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (ReviewSandboxConfig.isSandboxToken(accessToken)) {
      await _tokenStorage.clearTokens();
      _sandboxStore.reset();
      _onSandboxChanged(false);
      return;
    }
    _onSandboxChanged(false);
    await _delegate.logout();
  }
}

/// [AuthRepository] 인스턴스를 제공하는 Riverpod Provider이다.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final realRepo = GrepiuAuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: tokenStorage,
    config: ref.watch(appConfigProvider),
  );
  return SandboxAwareAuthRepository(
    delegate: realRepo,
    tokenStorage: tokenStorage,
    sandboxStore: ref.watch(reviewSandboxStoreProvider),
    onSandboxChanged: (enabled) =>
        ref.read(reviewSandboxProvider.notifier).setEnabled(enabled),
  );
});
