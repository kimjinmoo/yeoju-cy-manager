import 'package:flutter/foundation.dart';

/// 라이선스 키 구분 (`SALE`: 판매키, `TEST`: 테스트키)이다.
enum LicenseKeyType {
  /// 정식 판매키
  sale(value: 'SALE', label: '판매키'),

  /// 테스트/체험용 키
  test(value: 'TEST', label: '테스트키');

  const LicenseKeyType({required this.value, required this.label});

  /// API 전송용 문자열 값
  final String value;

  /// UI 표시 라벨
  final String label;

  /// 문자열 값으로부터 [LicenseKeyType]을 파싱한다.
  static LicenseKeyType fromRaw(String? raw) {
    if (raw != null && raw.trim().toUpperCase() == 'TEST') {
      return LicenseKeyType.test;
    }
    return LicenseKeyType.sale;
  }
}

/// 시디키 목록 상태 필터 옵션이다.
enum LicenseKeyStatusFilter {
  /// 전체 상태
  all(value: 'ALL', label: '전체 상태'),

  /// 사용 대기 (발급 완료 · 미등록)
  unused(value: 'UNUSED', label: '사용 대기'),

  /// 사용중 (인증 완료)
  active(value: 'ACTIVE', label: '사용중'),

  /// 만료 임박 (7일 내)
  expiringSoon(value: 'EXPIRING_SOON', label: '만료 임박'),

  /// 사용 중지 (수동 중지 및 만료 포함)
  stopped(value: 'STOPPED', label: '사용 중지'),

  /// 기간 만료
  expired(value: 'EXPIRED', label: '기간 만료');

  const LicenseKeyStatusFilter({required this.value, required this.label});

  /// API 쿼리 파라미터 값
  final String value;

  /// UI 표시 라벨
  final String label;
}

/// 판매처 필터 중 '미입력' 항목을 식별하기 위한 특수 토큰이다.
const String emptySalesLocationToken = '__EMPTY__';

/// 기본 판매처 추천 프리셋 목록이다.
const List<String> defaultSalesLocationPresets = [
  '여주 본점',
  '스마트스토어',
  '현장 판매',
  '내부 테스트',
];

/// 기간제 키 일수 추천 프리셋 목록이다.
const List<int> licensePeriodPresets = [7, 14, 30, 90, 180, 365];

/// 단건 라이선스 키 엔티티 모델이다.
@immutable
class LicenseKeyItem {
  /// [LicenseKeyItem] 인스턴스를 생성한다.
  const LicenseKeyItem({
    required this.key,
    this.device,
    this.reject = 'N',
    this.rejectReason,
    this.keyType,
    this.salesLocation,
    this.validDays,
    this.expireDate,
    this.activatedDate,
    this.memo,
    this.createDate,
    this.updateDate,
  });

  /// 서버 JSON 응답으로부터 [LicenseKeyItem]을 파싱한다.
  factory LicenseKeyItem.fromJson(Map<String, dynamic> json) {
    return LicenseKeyItem(
      key: (json['key'] as String?) ?? '',
      device: json['device'] as String?,
      reject: (json['reject'] as String?) ?? 'N',
      rejectReason: json['rejectReason'] as String?,
      keyType: json['keyType'] as String?,
      salesLocation: json['salesLocation'] as String?,
      validDays: (json['validDays'] as num?)?.toInt(),
      expireDate: json['expireDate'] as String?,
      activatedDate: json['activatedDate'] as String?,
      memo: json['memo'] as String?,
      createDate: json['createDate'] as String?,
      updateDate: json['updateDate'] as String?,
    );
  }

  /// 시디키 문자열
  final String key;

  /// 바인딩된 단말기 ID
  final String? device;

  /// 사용 중지 여부 (`Y` / `N`)
  final String reject;

  /// 사용 중지 사유 (`EXPIRED`, `MANUAL`)
  final String? rejectReason;

  /// 키 구분 (`SALE`, `TEST`)
  final String? keyType;

  /// 판매처 / 발급처
  final String? salesLocation;

  /// 유효 기간 일수 (0: 영구적, 1 이상: 기간제)
  final int? validDays;

  /// 만료 일시 (ISO 문자열)
  final String? expireDate;

  /// 최초 기기 인증 일시 (ISO 문자열)
  final String? activatedDate;

  /// 관리자 비고
  final String? memo;

  /// 발급 일시
  final String? createDate;

  /// 수정 일시
  final String? updateDate;

  /// 테스트키 여부를 반환한다.
  bool get isTestKey => (keyType ?? '').trim().toUpperCase() == 'TEST';

  /// 사용 중지 상태 여부를 반환한다.
  bool get isStopped => reject.trim().toUpperCase() == 'Y';

  /// 단말기가 연결(인증)된 상태인지 여부를 반환한다.
  bool get hasDevice => device != null && device!.trim().isNotEmpty;

  /// 영구적 라이선스 키 여부를 반환한다.
  bool get isPermanent => (validDays ?? 0) <= 0;
}

/// 키 상태별 요약 통계 모델이다.
@immutable
class LicenseKeySummary {
  /// [LicenseKeySummary] 인스턴스를 생성한다.
  const LicenseKeySummary({
    this.total = 0,
    this.active = 0,
    this.unused = 0,
    this.stopped = 0,
    this.expired = 0,
    this.expiringSoon = 0,
    this.saleCount = 0,
    this.testCount = 0,
  });

  /// 서버 JSON 응답으로부터 [LicenseKeySummary]를 파싱한다.
  factory LicenseKeySummary.fromJson(Map<String, dynamic> json) {
    return LicenseKeySummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      unused: (json['unused'] as num?)?.toInt() ?? 0,
      stopped: (json['stopped'] as num?)?.toInt() ?? 0,
      expired: (json['expired'] as num?)?.toInt() ?? 0,
      expiringSoon: (json['expiringSoon'] as num?)?.toInt() ?? 0,
      saleCount: (json['saleCount'] as num?)?.toInt() ?? 0,
      testCount: (json['testCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// 전체 키 수
  final int total;

  /// 사용중 키 수
  final int active;

  /// 사용 대기(미등록) 키 수
  final int unused;

  /// 사용 중지 키 수
  final int stopped;

  /// 기간 만료 키 수
  final int expired;

  /// 만료 임박(7일 내) 키 수
  final int expiringSoon;

  /// 판매키 수
  final int saleCount;

  /// 테스트키 수
  final int testCount;
}

/// 시디키 목록 페이징 응답 모델이다.
@immutable
class LicenseKeyPageResult {
  /// [LicenseKeyPageResult] 인스턴스를 생성한다.
  const LicenseKeyPageResult({
    required this.items,
    required this.totalPages,
    required this.totalCount,
  });

  /// 키 목록
  final List<LicenseKeyItem> items;

  /// 총 페이지 수 (최소 1)
  final int totalPages;

  /// 총 건수
  final int totalCount;
}

/// 시디키 신규 발급 요청 DTO이다.
@immutable
class LicenseKeyCreatePayload {
  /// [LicenseKeyCreatePayload] 인스턴스를 생성한다.
  const LicenseKeyCreatePayload({
    required this.count,
    required this.keyType,
    required this.salesLocation,
    required this.validDays,
    required this.memo,
  });

  /// 발급 수량 (1~100)
  final int count;

  /// 키 구분 (`SALE` / `TEST`)
  final LicenseKeyType keyType;

  /// 판매처 / 발급처
  final String salesLocation;

  /// 유효 기간 일수 (0: 영구적)
  final int validDays;

  /// 비고
  final String memo;

  /// API 요청용 JSON 맵으로 직렬화한다.
  Map<String, dynamic> toJson() => {
        'count': count,
        'keyType': keyType.value,
        'salesLocation': salesLocation.trim(),
        'validDays': validDays,
        'memo': memo.trim(),
      };
}

/// 시디키 메타데이터 수정 요청 DTO이다.
@immutable
class LicenseKeyUpdatePayload {
  /// [LicenseKeyUpdatePayload] 인스턴스를 생성한다.
  const LicenseKeyUpdatePayload({
    required this.key,
    required this.keyType,
    required this.salesLocation,
    required this.validDays,
    required this.recalculateExpire,
    required this.reactivate,
    required this.memo,
  });

  /// 대상 인증키
  final String key;

  /// 키 구분
  final LicenseKeyType keyType;

  /// 판매처 / 발급처
  final String salesLocation;

  /// 유효 기간 일수 (0: 영구적)
  final int validDays;

  /// 오늘 시점부터 만료일 재계산 여부
  final bool recalculateExpire;

  /// 사용 중지/만료 상태를 정상으로 복구할지 여부
  final bool reactivate;

  /// 비고
  final String memo;

  /// API 요청용 JSON 맵으로 직렬화한다.
  Map<String, dynamic> toJson() => {
        'key': key,
        'keyType': keyType.value,
        'salesLocation': salesLocation.trim(),
        'validDays': validDays,
        'recalculateExpire': recalculateExpire,
        'reactivate': reactivate,
        'memo': memo,
      };
}

/// 시디키 변경 이력 단건 모델이다.
@immutable
class LicenseKeyHistoryItem {
  /// [LicenseKeyHistoryItem] 인스턴스를 생성한다.
  const LicenseKeyHistoryItem({
    required this.id,
    required this.serviceType,
    required this.key,
    required this.actionType,
    this.summary,
    this.changedBy,
    this.beforeData,
    this.afterData,
    this.changedAt,
  });

  /// 서버 JSON 응답으로부터 [LicenseKeyHistoryItem]을 파싱한다.
  factory LicenseKeyHistoryItem.fromJson(Map<String, dynamic> json) {
    return LicenseKeyHistoryItem(
      id: (json['id'] as String?) ?? '',
      serviceType: (json['serviceType'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      actionType: (json['actionType'] as String?) ?? '',
      summary: json['summary'] as String?,
      changedBy: json['changedBy'] as String?,
      beforeData: json['beforeData'] is Map<String, dynamic>
          ? json['beforeData'] as Map<String, dynamic>
          : null,
      afterData: json['afterData'] is Map<String, dynamic>
          ? json['afterData'] as Map<String, dynamic>
          : null,
      changedAt: json['changedAt'] as String?,
    );
  }

  /// 이력 문서 ID
  final String id;

  /// 서비스 구분 (`MINIPOS`, `SIGN`)
  final String serviceType;

  /// 대상 시디키
  final String key;

  /// 변경 유형 (`ISSUE`, `UPDATE`, `ACTIVATE`, `DEVICE_INIT`, `STOP`, `RESUME`, `EXPIRE_BATCH`, `EXPIRE_AUTO`, `DELETE`)
  final String actionType;

  /// 변경 요약
  final String? summary;

  /// 작업자
  final String? changedBy;

  /// 변경 전 스냅샷
  final Map<String, dynamic>? beforeData;

  /// 변경 후 스냅샷
  final Map<String, dynamic>? afterData;

  /// 변경 일시
  final String? changedAt;
}

/// 변경 이력 페이징 응답 모델이다.
@immutable
class LicenseKeyHistoryPageResult {
  /// [LicenseKeyHistoryPageResult] 인스턴스를 생성한다.
  const LicenseKeyHistoryPageResult({
    required this.items,
    required this.totalPages,
    required this.totalCount,
  });

  /// 이력 목록
  final List<LicenseKeyHistoryItem> items;

  /// 총 페이지 수 (최소 1)
  final int totalPages;

  /// 총 건수
  final int totalCount;
}

/// 일별 판매(기기 인증) 통계 항목 모델이다.
@immutable
class DailySalesStatItem {
  /// [DailySalesStatItem] 인스턴스를 생성한다.
  const DailySalesStatItem({
    required this.date,
    required this.count,
  });

  /// 서버 JSON 응답으로부터 [DailySalesStatItem]을 파싱한다.
  factory DailySalesStatItem.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'] ?? json['cnt'] ?? 0;
    return DailySalesStatItem(
      date: (json['date'] as String?) ?? '',
      count: (rawCount as num).toInt(),
    );
  }

  /// 날짜 (`YYYY-MM-dd`)
  final String date;

  /// 인증(판매) 건수
  final int count;
}
