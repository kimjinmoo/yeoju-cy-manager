import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 서버 실행 환경 프리셋을 정의한다.
enum ServerEnvironment {
  /// 운영 서버 (https://conf.grepiu.com)
  prod(
    id: 'prod',
    label: '운영 서버',
    apiBaseUrl: 'https://conf.grepiu.com',
    webHost: 'https://www.grepiu.com',
    googleServerClientId:
        '661595256339-sl014pltv6c4uq46ppte2ocii5941air.apps.googleusercontent.com',
  ),

  /// 로컬 서버 (http://localhost:8010)
  local(
    id: 'local',
    label: '로컬 서버 (localhost)',
    apiBaseUrl: 'http://localhost:8010',
    webHost: 'http://localhost:3000',
    googleServerClientId:
        '661595256339-33npivg897thbdublr0i6c06as1tjmm4.apps.googleusercontent.com',
  ),

  /// Android 에뮬레이터 로컬 호스트 브릿지 (http://10.0.2.2:8010)
  emulator(
    id: 'emulator',
    label: 'Android 에뮬레이터 (10.0.2.2)',
    apiBaseUrl: 'http://10.0.2.2:8010',
    webHost: 'http://10.0.2.2:3000',
    googleServerClientId:
        '661595256339-33npivg897thbdublr0i6c06as1tjmm4.apps.googleusercontent.com',
  );

  const ServerEnvironment({
    required this.id,
    required this.label,
    required this.apiBaseUrl,
    required this.webHost,
    required this.googleServerClientId,
  });

  /// 환경 식별자 문자열
  final String id;

  /// UI 표시 이름
  final String label;

  /// API 기본 URL
  final String apiBaseUrl;

  /// 전달 URL 생성용 웹 호스트
  final String webHost;

  /// Google OAuth2 서버 검증용 Web Client ID
  final String googleServerClientId;

  /// 문자열 ID로부터 환경 열거형을 조회한다.
  static ServerEnvironment fromId(String? value) {
    return ServerEnvironment.values.firstWhere(
      (e) => e.id == value,
      orElse: () => ServerEnvironment.prod,
    );
  }
}

/// 앱 전역 API 및 인증 환경 설정 모델이다.
@immutable
class AppConfig {
  /// [AppConfig] 인스턴스를 생성한다.
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.webHost,
    required this.googleServerClientId,
    this.customApiBaseUrl,
  });

  /// `--dart-define` 값을 반영한 기본 설정을 반환한다.
  factory AppConfig.initial() {
    const envRaw = String.fromEnvironment('ENV', defaultValue: 'prod');
    const urlOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const webOverride = String.fromEnvironment('WEB_HOST', defaultValue: '');
    const clientOverride = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );

    final env = ServerEnvironment.fromId(envRaw);
    final apiUrl = urlOverride.isNotEmpty ? urlOverride : env.apiBaseUrl;
    final webUrl = webOverride.isNotEmpty ? webOverride : env.webHost;
    final clientId =
        clientOverride.isNotEmpty ? clientOverride : env.googleServerClientId;

    return AppConfig(
      environment: env,
      apiBaseUrl: _stripTrailingSlash(apiUrl),
      webHost: _stripTrailingSlash(webUrl),
      googleServerClientId: clientId,
      customApiBaseUrl: urlOverride.isNotEmpty ? _stripTrailingSlash(urlOverride) : null,
    );
  }

  /// 현재 선택된 서버 환경 프리셋
  final ServerEnvironment environment;

  /// 활성 API 서버 URL
  final String apiBaseUrl;

  /// 시디키 전달 URL에 사용할 웹 호스트
  final String webHost;

  /// Google ID Token 검증용 서버 Client ID
  final String googleServerClientId;

  /// 사용자가 직접 입력한 서버 URL (설정된 경우 우선 적용)
  final String? customApiBaseUrl;

  /// 프리셋 변경 또는 직접 URL을 적용한 새 설정을 반환한다.
  AppConfig copyWith({
    ServerEnvironment? environment,
    String? apiBaseUrl,
    String? webHost,
    String? googleServerClientId,
    String? customApiBaseUrl,
    bool clearCustomUrl = false,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: _stripTrailingSlash(apiBaseUrl ?? this.apiBaseUrl),
      webHost: _stripTrailingSlash(webHost ?? this.webHost),
      googleServerClientId: googleServerClientId ?? this.googleServerClientId,
      customApiBaseUrl:
          clearCustomUrl ? null : (customApiBaseUrl ?? this.customApiBaseUrl),
    );
  }

  static String _stripTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

/// 앱 설정 상태를 관리하는 Notifier이다.
class AppConfigNotifier extends Notifier<AppConfig> {
  @override
  AppConfig build() => AppConfig.initial();

  /// 서버 프리셋을 전환한다.
  void selectEnvironment(ServerEnvironment env) {
    state = state.copyWith(
      environment: env,
      apiBaseUrl: env.apiBaseUrl,
      webHost: env.webHost,
      googleServerClientId: env.googleServerClientId,
      clearCustomUrl: true,
    );
  }

  /// 사용자 지정 API 서버 URL을 적용한다.
  void setCustomApiBaseUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    final normalized =
        trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    final isLocal =
        normalized.contains('localhost') ||
        normalized.contains('127.0.0.1') ||
        normalized.contains('10.0.2.2');
    final env = isLocal ? ServerEnvironment.local : ServerEnvironment.prod;
    state = state.copyWith(
      environment: env,
      apiBaseUrl: normalized,
      webHost: env.webHost,
      googleServerClientId: env.googleServerClientId,
      customApiBaseUrl: normalized,
    );
  }
}

/// 전역 [AppConfig] 상태를 제공하는 Riverpod Provider이다.
final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);
