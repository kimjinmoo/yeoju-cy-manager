import 'package:flutter/foundation.dart';

import 'auth_user.dart';

/// 앱 인증 흐름의 현재 상태를 나타낸다.
enum AuthStatus {
  /// 초기 자동 로그인 및 세션 확인 중
  initializing,

  /// 미인증 상태 (로그인 화면)
  unauthenticated,

  /// 인증 및 관리자 권한 확인 완료 (관리 화면)
  authenticated,

  /// 로그인은 성공했으나 관리자 권한(`ADMIN`, `YEOJU_CYCLE_ADMIN`) 미보유
  forbidden,
}

/// 인증 상태 및 로그인 진행 상태를 보관하는 불변 상태 모델이다.
@immutable
class AuthState {
  /// [AuthState] 인스턴스를 생성한다.
  const AuthState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// 앱 시작 시 초기 상태를 반환한다.
  const AuthState.initial()
      : status = AuthStatus.initializing,
        user = null,
        isSubmitting = false,
        errorMessage = null;

  /// 현재 인증 상태
  final AuthStatus status;

  /// 로그인된 사용자 정보
  final AuthUser? user;

  /// 로그인 요청 진행 중 여부
  final bool isSubmitting;

  /// 최근 발생한 인증 오류 메시지
  final String? errorMessage;

  /// 일부 필드를 갱신한 새 [AuthState]를 반환한다.
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool clearUser = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
