import 'package:flutter/foundation.dart';

/// 로그인한 사용자 정보 및 여주자전거여행 관리자 권한 판별 모델이다.
@immutable
class AuthUser {
  /// [AuthUser] 인스턴스를 생성한다.
  const AuthUser({
    required this.email,
    required this.nickname,
    required this.roles,
    this.provider,
  });

  /// `/api/v1/auth/me` JSON 응답으로부터 [AuthUser]를 파싱한다.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final parsedRoles = <String>[];
    if (rawRoles is List) {
      for (final item in rawRoles) {
        final normalized = _normalizeRole(item.toString());
        if (normalized.isNotEmpty) {
          parsedRoles.add(normalized);
        }
      }
    }

    return AuthUser(
      email: (json['email'] as String?) ?? '',
      nickname: (json['nickname'] as String?) ?? '',
      roles: List.unmodifiable(parsedRoles),
      provider: json['provider'] as String?,
    );
  }

  /// 시디키·간편서명 관리 API 접근이 허용된 관리자 역할 목록이다.
  static const allowedAdminRoles = {'ADMIN', 'YEOJU_CYCLE_ADMIN'};

  /// 사용자 이메일
  final String email;

  /// 사용자 닉네임
  final String nickname;

  /// 정규화된 권한 목록 (`ROLE_` 접두사 제거, 대문자)
  final List<String> roles;

  /// OAuth2 연동 제공자 (예: `google`, 일반 가입 시 `null`)
  final String? provider;

  /// MiniPos 및 간편서명 키 관리 화면 접근 권한 보유 여부를 반환한다.
  bool get hasCycleAdminRole => roles.any(
        (role) => allowedAdminRoles.contains(_normalizeRole(role)),
      );

  /// 화면 표시용 사용자 이름을 반환한다.
  String get displayName => nickname.trim().isNotEmpty ? nickname : email;

  static String _normalizeRole(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper.startsWith('ROLE_')) {
      return upper.substring('ROLE_'.length);
    }
    return upper;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.email == email &&
        other.nickname == nickname &&
        other.provider == provider &&
        listEquals(other.roles, roles);
  }

  @override
  int get hashCode => Object.hash(email, nickname, provider, Object.hashAll(roles));
}
