import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱 전역 Google Analytics(Firebase Analytics) 이벤트·화면 수집 추상화 인터페이스이다.
///
/// Firebase 설정 파일(`google-services.json`, `GoogleService-Info.plist`)이 아직 없거나
/// 테스트 환경인 경우에도 앱 크래시 없이 안전하게 무동작(No-op)으로 폴백한다.
abstract class AppAnalytics {
  /// [AppAnalytics] 기본 생성자이다.
  const AppAnalytics();

  /// Firebase Analytics 인스턴스가 정상 초기화되어 활성화되었는지 여부를 반환한다.
  bool get isAvailable;

  /// GoRouter 등 네비게이션 스택 전환을 자동 추적하기 위한 [NavigatorObserver]를 반환한다.
  NavigatorObserver? buildNavigatorObserver();

  /// Analytics 수집 활성/비활성 상태를 전환한다.
  Future<void> setCollectionEnabled(bool enabled);

  /// 화면 조회(`screen_view`) 이벤트를 기록한다.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  /// 로그인 성공(`login`) 이벤트를 기록한다.
  Future<void> logLogin({required String method});

  /// 로그인 실패(`login_failed`) 이벤트를 기록한다.
  Future<void> logLoginFailed({required String method});

  /// 로그아웃(`logout`) 이벤트를 기록한다.
  Future<void> logLogout();

  /// 시디키·간편서명 관리 액션을 비식별 파라미터로 기록한다.
  ///
  /// 시디키 원문, 이메일 등 민감 정보(PII)는 절대 포함하지 않는다.
  Future<void> logLicenseAction({
    required String action,
    required String service,
    Map<String, Object>? parameters,
  });
}

/// 설정 미보유 또는 위젯 테스트 환경에서 사용하는 무동작(No-op) 구현체이다.
class NoopAppAnalytics extends AppAnalytics {
  /// [NoopAppAnalytics] 인스턴스를 생성한다.
  const NoopAppAnalytics();

  @override
  bool get isAvailable => false;

  @override
  NavigatorObserver? buildNavigatorObserver() => null;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> logLogin({required String method}) async {}

  @override
  Future<void> logLoginFailed({required String method}) async {}

  @override
  Future<void> logLogout() async {}

  @override
  Future<void> logLicenseAction({
    required String action,
    required String service,
    Map<String, Object>? parameters,
  }) async {}
}

/// Firebase Core 및 Google Analytics SDK를 안전하게 감싸는 구현체이다.
class FirebaseAppAnalytics extends AppAnalytics {
  FirebaseAppAnalytics._(this._analytics);

  final FirebaseAnalytics? _analytics;
  bool _collectionEnabled = true;

  /// Firebase 초기화를 시도하고 [FirebaseAppAnalytics]를 생성한다.
  ///
  /// 1) `--dart-define`으로 `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
  ///    `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`가 모두 주입된 경우
  ///    해당 [FirebaseOptions]로 초기화한다.
  /// 2) 그렇지 않으면 네이티브 설정 파일(`google-services.json`,
  ///    `GoogleService-Info.plist`) 기반 기본 초기화를 시도한다.
  /// 3) 설정 파일이 아직 없는 경우에도 예외를 삼켜 앱이 정상 기동되도록 보장한다.
  static Future<FirebaseAppAnalytics> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        final options = _optionsFromDefines();
        if (options != null) {
          await Firebase.initializeApp(options: options);
        } else {
          await Firebase.initializeApp();
        }
      }
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAppAnalytics._(FirebaseAnalytics.instance);
      }
    } catch (_) {
      // Firebase 설정 파일이 아직 추가되지 않은 경우 크래시 없이 비활성 상태로 유지한다.
    }
    return FirebaseAppAnalytics._(null);
  }

  static FirebaseOptions? _optionsFromDefines() {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        senderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }

  @override
  bool get isAvailable => _analytics != null;

  @override
  NavigatorObserver? buildNavigatorObserver() {
    final analytics = _analytics;
    if (analytics == null) return null;
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    _collectionEnabled = enabled;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {
      // 분석 수집 토글 실패가 사용자 흐름을 방해하지 않도록 무시한다.
    }
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_collectionEnabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (_) {}
  }

  @override
  Future<void> logLogin({required String method}) async {
    if (!_collectionEnabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  @override
  Future<void> logLoginFailed({required String method}) async {
    if (!_collectionEnabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(
        name: 'login_failed',
        parameters: {'method': method},
      );
    } catch (_) {}
  }

  @override
  Future<void> logLogout() async {
    if (!_collectionEnabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: 'logout');
    } catch (_) {}
  }

  @override
  Future<void> logLicenseAction({
    required String action,
    required String service,
    Map<String, Object>? parameters,
  }) async {
    if (!_collectionEnabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(
        name: action,
        parameters: <String, Object>{
          'service': service,
          ...?parameters,
        },
      );
    } catch (_) {}
  }
}

/// 앱 전역 [AppAnalytics] 인스턴스를 제공하는 Riverpod Provider이다.
///
/// 실제 앱 실행 시 `main.dart`에서 [FirebaseAppAnalytics.initialize] 결과로 오버라이드되며,
/// 테스트 환경에서는 안전한 [NoopAppAnalytics]가 기본 제공된다.
final appAnalyticsProvider = Provider<AppAnalytics>(
  (ref) => const NoopAppAnalytics(),
);
