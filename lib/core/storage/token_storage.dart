import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 인증 토큰 및 서버 URL을 안전하게 저장·조회하는 추상 인터페이스이다.
abstract class TokenStorage {
  /// 저장된 Access Token을 반환한다.
  Future<String?> getAccessToken();

  /// 저장된 Refresh Token을 반환한다.
  Future<String?> getRefreshToken();

  /// Access Token과 Refresh Token을 함께 저장한다.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// 저장된 모든 인증 토큰을 삭제한다.
  Future<void> clearTokens();

  /// 마지막으로 선택한 서버 환경 ID를 조회한다.
  Future<String?> getSavedEnvId();

  /// 마지막으로 입력한 사용자 지정 API URL을 조회한다.
  Future<String?> getSavedCustomUrl();

  /// 선택한 서버 환경 정보를 저장한다.
  Future<void> saveServerPreference({
    required String envId,
    String? customUrl,
  });
}

/// `flutter_secure_storage`를 사용하는 [TokenStorage] 구현체이다.
class SecureTokenStorage implements TokenStorage {
  /// [SecureTokenStorage] 인스턴스를 생성한다.
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  static const _accessTokenKey = 'grepiu_access_token';
  static const _refreshTokenKey = 'grepiu_refresh_token';
  static const _envIdKey = 'grepiu_server_env';
  static const _customUrlKey = 'grepiu_server_custom_url';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  @override
  Future<String?> getSavedEnvId() => _storage.read(key: _envIdKey);

  @override
  Future<String?> getSavedCustomUrl() => _storage.read(key: _customUrlKey);

  @override
  Future<void> saveServerPreference({
    required String envId,
    String? customUrl,
  }) async {
    await _storage.write(key: _envIdKey, value: envId);
    if (customUrl == null || customUrl.isEmpty) {
      await _storage.delete(key: _customUrlKey);
    } else {
      await _storage.write(key: _customUrlKey, value: customUrl);
    }
  }
}

/// [TokenStorage]를 제공하는 Riverpod Provider이다.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
