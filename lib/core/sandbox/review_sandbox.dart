import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_user.dart';
import '../../features/license_keys/domain/license_key_models.dart';
import '../../features/license_keys/domain/license_service_type.dart';

/// 스토어 심사(Google Play / App Store)용 격리 샌드박스 계정 및 토큰 상수 정의이다.
///
/// 심사관이 앱 기능을 검증할 때 실제 운영 서버(`conf.grepiu.com`)나 실데이터에
/// 접근하지 않고 로컬 인메모리 목업 데이터로만 동작하도록 분리한다.
abstract final class ReviewSandboxConfig {
  /// 스토어 심사용 테스트 아이디
  static const String reviewId = 'test';

  /// 스토어 심사용 테스트 비밀번호
  static const String reviewPassword = r'xptmxm1!';

  /// 로컬 샌드박스 세션 식별용 Access Token 마커
  static const String sandboxAccessToken = '__yeoju_review_sandbox_access__';

  /// 로컬 샌드박스 세션 식별용 Refresh Token 마커
  static const String sandboxRefreshToken = '__yeoju_review_sandbox_refresh__';

  /// 심사 테스트 계정 전용 사용자 프로필
  static const AuthUser reviewUser = AuthUser(
    email: 'test@review.sandbox',
    nickname: '스토어 심사 테스트 계정',
    roles: ['YEOJU_CYCLE_ADMIN'],
    provider: 'review_sandbox',
  );

  /// 입력한 자격 증명이 심사용 테스트 계정과 일치하는지 판별한다.
  static bool isReviewCredentials({
    required String id,
    required String password,
  }) {
    return id.trim() == reviewId && password == reviewPassword;
  }

  /// 입력한 아이디가 심사용 테스트 아이디인지 판별한다.
  static bool isReviewId(String id) => id.trim() == reviewId;

  /// 저장된 토큰이 심사용 샌드박스 세션 마커인지 판별한다.
  static bool isSandboxToken(String? token) => token == sandboxAccessToken;
}

/// 현재 앱이 스토어 심사 샌드박스 모드로 동작 중인지 관리하는 Notifier이다.
class ReviewSandboxNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// 샌드박스 모드 활성화 여부를 갱신한다.
  void setEnabled(bool enabled) {
    if (state != enabled) {
      state = enabled;
    }
  }
}

/// 스토어 심사 샌드박스 모드 상태 Provider이다.
final reviewSandboxProvider = NotifierProvider<ReviewSandboxNotifier, bool>(
  ReviewSandboxNotifier.new,
);

/// 심사용 샌드박스 모드에서 사용하는 인메모리 시디키·이력 저장소이다.
class ReviewSandboxStore {
  /// [ReviewSandboxStore] 인스턴스를 생성하고 초기 목업 데이터를 적재한다.
  ReviewSandboxStore() {
    reset();
  }

  final Map<LicenseServiceType, List<LicenseKeyItem>> _keys = {};
  final Map<LicenseServiceType, List<LicenseKeyHistoryItem>> _histories = {};
  int _seq = 100;

  /// 특정 서비스의 시디키 목록을 반환한다.
  List<LicenseKeyItem> keysFor(LicenseServiceType type) =>
      _keys[type] ??= [];

  /// 특정 서비스의 변경 이력 목록을 반환한다.
  List<LicenseKeyHistoryItem> historiesFor(LicenseServiceType type) =>
      _histories[type] ??= [];

  /// 다음 시퀀스 번호를 발급한다.
  int nextSeq() => ++_seq;

  /// 모든 샌드박스 데이터를 초기 상태(실데이터와 무관한 목업 데이터)로 재설정한다.
  void reset() {
    final now = DateTime.now();
    _seq = 100;

    _keys[LicenseServiceType.miniPos] = [
      LicenseKeyItem(
        key: 'DEMO-MPOS-0001-AAAA',
        device: 'DEMO-POS-01',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '여주 본점 (샘플)',
        validDays: 365,
        expireDate: now.add(const Duration(days: 240)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 125)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 130)).toIso8601String(),
        memo: '본점 카운터 1번 단말기',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0002-BBBB',
        device: 'DEMO-POS-02',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '이포보 지점 (샘플)',
        validDays: 0,
        activatedDate: now.subtract(const Duration(days: 45)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 50)).toIso8601String(),
        memo: '영구 라이선스 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0003-CCCC',
        device: 'DEMO-POS-03',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '스마트스토어 (샘플)',
        validDays: 30,
        expireDate: now.add(const Duration(days: 4)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 26)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 27)).toIso8601String(),
        memo: '만료 임박 상태 샘플 (D-4)',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0004-DDDD',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '강천보 지점 (샘플)',
        validDays: 365,
        createDate: now.subtract(const Duration(days: 2)).toIso8601String(),
        memo: '미사용 대기 상태 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0005-EEEE',
        device: 'DEMO-QA-01',
        reject: 'Y',
        rejectReason: 'MANUAL',
        keyType: 'TEST',
        salesLocation: '내부 테스트',
        validDays: 14,
        expireDate: now.add(const Duration(days: 10)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 4)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 5)).toIso8601String(),
        memo: '수동 중지 상태 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0006-FFFF',
        device: 'DEMO-POS-04',
        reject: 'Y',
        rejectReason: 'EXPIRED',
        keyType: 'SALE',
        salesLocation: '현장 판매 (샘플)',
        validDays: 30,
        expireDate: now.subtract(const Duration(days: 3)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 33)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 35)).toIso8601String(),
        memo: '기간 만료 처리 완료 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0007-GGGG',
        device: 'DEMO-QA-02',
        reject: 'N',
        keyType: 'TEST',
        validDays: 7,
        expireDate: now.subtract(const Duration(days: 1)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 8)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 9)).toIso8601String(),
        memo: '만료 배치 점검 대상 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-MPOS-0008-HHHH',
        reject: 'N',
        keyType: 'TEST',
        salesLocation: '내부 테스트',
        validDays: 7,
        createDate: now.subtract(const Duration(hours: 12)).toIso8601String(),
        memo: '체험용 테스트키 대기 샘플',
      ),
    ];

    _keys[LicenseServiceType.sign] = [
      LicenseKeyItem(
        key: 'DEMO-SIGN-0001-AAAA',
        device: 'DEMO-PAD-01',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '여주 본점 (샘플)',
        validDays: 0,
        activatedDate: now.subtract(const Duration(days: 60)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 62)).toIso8601String(),
        memo: '간편서명 태블릿 샘플 #1',
      ),
      LicenseKeyItem(
        key: 'DEMO-SIGN-0002-BBBB',
        device: 'DEMO-PAD-02',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '강천보 지점 (샘플)',
        validDays: 365,
        expireDate: now.add(const Duration(days: 180)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 185)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 190)).toIso8601String(),
        memo: '간편서명 기간제 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-SIGN-0003-CCCC',
        reject: 'N',
        keyType: 'TEST',
        salesLocation: '내부 테스트',
        validDays: 7,
        createDate: now.subtract(const Duration(days: 1)).toIso8601String(),
        memo: '테스트키 미사용 샘플',
      ),
      LicenseKeyItem(
        key: 'DEMO-SIGN-0004-DDDD',
        device: 'DEMO-PAD-03',
        reject: 'N',
        keyType: 'SALE',
        salesLocation: '스마트스토어 (샘플)',
        validDays: 30,
        expireDate: now.add(const Duration(days: 5)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 25)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 26)).toIso8601String(),
        memo: '만료 임박 태블릿 (D-5)',
      ),
      LicenseKeyItem(
        key: 'DEMO-SIGN-0005-EEEE',
        device: 'DEMO-PAD-04',
        reject: 'Y',
        rejectReason: 'EXPIRED',
        keyType: 'SALE',
        validDays: 30,
        expireDate: now.subtract(const Duration(days: 5)).toIso8601String(),
        activatedDate: now.subtract(const Duration(days: 35)).toIso8601String(),
        createDate: now.subtract(const Duration(days: 36)).toIso8601String(),
        memo: '기간 만료 샘플',
      ),
    ];

    _histories[LicenseServiceType.miniPos] = [
      LicenseKeyHistoryItem(
        id: 'demo-hist-1',
        serviceType: 'MINI_POS',
        key: 'DEMO-MPOS-0005-EEEE',
        actionType: 'STOP',
        summary: '관리자 수동 사용 중지',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
        beforeData: const {
          'reject': 'N',
          'device': 'DEMO-QA-01',
        },
        afterData: const {
          'reject': 'Y',
          'rejectReason': 'MANUAL',
          'device': 'DEMO-QA-01',
        },
      ),
      LicenseKeyHistoryItem(
        id: 'demo-hist-2',
        serviceType: 'MINI_POS',
        key: 'DEMO-MPOS-0001-AAAA',
        actionType: 'UPDATE',
        summary: '판매처 및 비고 수정',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: now.subtract(const Duration(days: 1)).toIso8601String(),
        beforeData: const {
          'keyType': 'SALE',
          'salesLocation': '현장 판매',
          'validDays': 365,
          'memo': '초기 발급',
        },
        afterData: const {
          'keyType': 'SALE',
          'salesLocation': '여주 본점 (샘플)',
          'validDays': 365,
          'memo': '본점 카운터 1번 단말기',
        },
      ),
      LicenseKeyHistoryItem(
        id: 'demo-hist-3',
        serviceType: 'MINI_POS',
        key: 'DEMO-MPOS-0006-FFFF',
        actionType: 'EXPIRE_BATCH',
        summary: '만료 배치 점검으로 사용 중지',
        changedBy: 'system',
        changedAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        beforeData: const {
          'reject': 'N',
          'device': 'DEMO-POS-04',
        },
        afterData: const {
          'reject': 'Y',
          'rejectReason': 'EXPIRED',
          'device': 'DEMO-POS-04',
        },
      ),
      LicenseKeyHistoryItem(
        id: 'demo-hist-4',
        serviceType: 'MINI_POS',
        key: 'DEMO-MPOS-0004-DDDD',
        actionType: 'ISSUE',
        summary: '신규 판매키 발급',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: now.subtract(const Duration(days: 2)).toIso8601String(),
        afterData: const {
          'keyType': 'SALE',
          'salesLocation': '강천보 지점 (샘플)',
          'validDays': 365,
          'memo': '미사용 대기 상태 샘플',
        },
      ),
    ];

    _histories[LicenseServiceType.sign] = [
      LicenseKeyHistoryItem(
        id: 'demo-hist-5',
        serviceType: 'SIGN',
        key: 'DEMO-SIGN-0001-AAAA',
        actionType: 'ACTIVATE',
        summary: '최초 단말기 인증 완료',
        changedBy: 'device:DEMO-PAD-01',
        changedAt: now.subtract(const Duration(days: 60)).toIso8601String(),
        beforeData: const {'device': ''},
        afterData: const {'device': 'DEMO-PAD-01'},
      ),
      LicenseKeyHistoryItem(
        id: 'demo-hist-6',
        serviceType: 'SIGN',
        key: 'DEMO-SIGN-0005-EEEE',
        actionType: 'EXPIRE_BATCH',
        summary: '만료 배치 점검으로 사용 중지',
        changedBy: 'system',
        changedAt: now.subtract(const Duration(days: 5)).toIso8601String(),
        beforeData: const {'reject': 'N', 'device': 'DEMO-PAD-04'},
        afterData: const {
          'reject': 'Y',
          'rejectReason': 'EXPIRED',
          'device': 'DEMO-PAD-04',
        },
      ),
      LicenseKeyHistoryItem(
        id: 'demo-hist-7',
        serviceType: 'SIGN',
        key: 'DEMO-SIGN-0003-CCCC',
        actionType: 'ISSUE',
        summary: '테스트키 신규 발급',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: now.subtract(const Duration(days: 1)).toIso8601String(),
        afterData: const {
          'keyType': 'TEST',
          'salesLocation': '내부 테스트',
          'validDays': 7,
          'memo': '테스트키 미사용 샘플',
        },
      ),
    ];
  }
}

/// [ReviewSandboxStore] 싱글턴 인스턴스를 제공하는 Riverpod Provider이다.
final reviewSandboxStoreProvider = Provider<ReviewSandboxStore>((ref) {
  return ReviewSandboxStore();
});
