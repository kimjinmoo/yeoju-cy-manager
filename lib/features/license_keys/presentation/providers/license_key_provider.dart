import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/sandbox/review_sandbox.dart';
import '../../data/license_key_repository.dart';
import '../../domain/license_key_models.dart';
import '../../domain/license_service_type.dart';

/// 서비스별 시디키 목록·필터·요약 통계 상태 모델이다.
@immutable
class LicenseKeyState {
  /// [LicenseKeyState] 인스턴스를 생성한다.
  const LicenseKeyState({
    this.items = const [],
    this.summary = const LicenseKeySummary(),
    this.salesLocations = const [],
    this.isLoading = true,
    this.isBatchRunning = false,
    this.statusFilter = LicenseKeyStatusFilter.all,
    this.keyTypeFilter,
    this.salesLocationFilter = '',
    this.searchKeyword = '',
    this.page = 0,
    this.pageSize = 10,
    this.totalCount = 0,
    this.totalPages = 1,
    this.errorMessage,
  });

  /// 현재 페이지의 시디키 목록
  final List<LicenseKeyItem> items;

  /// 상태별 요약 카운트
  final LicenseKeySummary summary;

  /// 서버에서 조회된 고유 판매처 목록
  final List<String> salesLocations;

  /// 목록 로딩 여부
  final bool isLoading;

  /// 만료 배치 실행 중 여부
  final bool isBatchRunning;

  /// 선택된 상태 필터
  final LicenseKeyStatusFilter statusFilter;

  /// 선택된 키 구분 필터 (null이면 전체)
  final LicenseKeyType? keyTypeFilter;

  /// 선택된 판매처 필터 (빈 문자열: 전체, `__EMPTY__`: 미입력)
  final String salesLocationFilter;

  /// 검색어
  final String searchKeyword;

  /// 현재 페이지 (0-based)
  final int page;

  /// 페이지 크기
  final int pageSize;

  /// 전체 검색 결과 건수
  final int totalCount;

  /// 전체 페이지 수
  final int totalPages;

  /// 최근 오류 메시지
  final String? errorMessage;

  /// 발급/수정 모달에서 추천 칩으로 표시할 판매처 목록을 생성한다.
  List<String> get knownSalesLocations {
    final merged = <String>{
      ...defaultSalesLocationPresets,
      ...salesLocations,
      for (final item in items)
        if (item.salesLocation != null && item.salesLocation!.trim().isNotEmpty)
          item.salesLocation!.trim(),
    };
    return merged.take(10).toList();
  }

  /// 필터 드롭다운용 가나다순 정렬 판매처 목록을 생성한다.
  List<String> get filterSalesLocations {
    final merged = <String>{
      ...salesLocations,
      for (final item in items)
        if (item.salesLocation != null && item.salesLocation!.trim().isNotEmpty)
          item.salesLocation!.trim(),
    };
    final list = merged.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  /// 일부 필드를 갱신한 새 [LicenseKeyState]를 반환한다.
  LicenseKeyState copyWith({
    List<LicenseKeyItem>? items,
    LicenseKeySummary? summary,
    List<String>? salesLocations,
    bool? isLoading,
    bool? isBatchRunning,
    LicenseKeyStatusFilter? statusFilter,
    LicenseKeyType? keyTypeFilter,
    bool clearKeyTypeFilter = false,
    String? salesLocationFilter,
    String? searchKeyword,
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LicenseKeyState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      salesLocations: salesLocations ?? this.salesLocations,
      isLoading: isLoading ?? this.isLoading,
      isBatchRunning: isBatchRunning ?? this.isBatchRunning,
      statusFilter: statusFilter ?? this.statusFilter,
      keyTypeFilter:
          clearKeyTypeFilter ? null : (keyTypeFilter ?? this.keyTypeFilter),
      salesLocationFilter: salesLocationFilter ?? this.salesLocationFilter,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// [LicenseServiceType]별 시디키 목록·필터·요약·CRUD 액션을 관리하는 Notifier이다.
class LicenseKeyNotifier extends Notifier<LicenseKeyState> {
  /// [LicenseKeyNotifier] 인스턴스를 생성한다.
  LicenseKeyNotifier(this.serviceType);

  /// 대상 서비스 (`miniPos` 또는 `sign`)
  final LicenseServiceType serviceType;

  @override
  LicenseKeyState build() {
    ref.watch(reviewSandboxProvider);
    Future.microtask(refreshAll);
    return const LicenseKeyState();
  }

  /// 키 목록, 요약 통계, 판매처 목록을 모두 새로고침한다.
  Future<void> refreshAll() async {
    await Future.wait([
      loadKeys(),
      loadSummaryAndLocations(),
    ]);
  }

  /// 현재 필터 조건으로 시디키 목록을 조회한다.
  Future<void> loadKeys() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(licenseKeyRepositoryProvider).fetchKeys(
            serviceType: serviceType,
            page: state.page,
            size: state.pageSize,
            keyword: state.searchKeyword,
            status: state.statusFilter,
            keyType: state.keyTypeFilter,
            salesLocation: state.salesLocationFilter,
          );
      state = state.copyWith(
        items: result.items,
        totalCount: result.totalCount,
        totalPages: result.totalPages,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: extractErrorMessage(
          error,
          fallback: '시디키 목록을 불러오지 못했습니다.',
        ),
      );
    }
  }

  /// 요약 통계와 고유 판매처 목록을 조회한다.
  Future<void> loadSummaryAndLocations() async {
    final repo = ref.read(licenseKeyRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.fetchSummary(serviceType),
        repo.fetchSalesLocations(serviceType),
      ]);
      state = state.copyWith(
        summary: results[0] as LicenseKeySummary,
        salesLocations: results[1] as List<String>,
      );
    } catch (_) {
      // 요약/판매처 보조 데이터 실패는 메인 목록 에러를 덮어쓰지 않는다.
    }
  }

  /// 상태 필터를 변경하고 첫 페이지부터 다시 조회한다.
  Future<void> setStatusFilter(LicenseKeyStatusFilter next) async {
    state = state.copyWith(statusFilter: next, page: 0);
    await loadKeys();
  }

  /// 키 구분 필터를 변경하고 첫 페이지부터 다시 조회한다.
  Future<void> setKeyTypeFilter(LicenseKeyType? next) async {
    state = state.copyWith(
      keyTypeFilter: next,
      clearKeyTypeFilter: next == null,
      page: 0,
    );
    await loadKeys();
  }

  /// 판매처 필터를 변경하고 첫 페이지부터 다시 조회한다.
  Future<void> setSalesLocationFilter(String next) async {
    state = state.copyWith(salesLocationFilter: next, page: 0);
    await loadKeys();
  }

  /// 검색어를 변경하고 첫 페이지부터 다시 조회한다.
  Future<void> setSearchKeyword(String keyword) async {
    final normalized = keyword.trim();
    if (normalized == state.searchKeyword) return;
    state = state.copyWith(searchKeyword: normalized, page: 0);
    await loadKeys();
  }

  /// 페이지 번호를 이동한다.
  Future<void> goToPage(int nextPage) async {
    if (nextPage < 0 || nextPage >= state.totalPages || nextPage == state.page) {
      return;
    }
    state = state.copyWith(page: nextPage);
    await loadKeys();
  }

  /// 페이지 크기를 변경하고 첫 페이지부터 다시 조회한다.
  Future<void> setPageSize(int nextSize) async {
    state = state.copyWith(pageSize: nextSize, page: 0);
    await loadKeys();
  }

  void _trackAction(
    String action, {
    Map<String, Object>? parameters,
  }) {
    if (ref.read(reviewSandboxProvider)) return;
    unawaited(
      ref.read(appAnalyticsProvider).logLicenseAction(
            action: action,
            service: serviceType.deliveryType,
            parameters: parameters,
          ),
    );
  }

  /// 시디키를 일괄 발급하고 목록을 새로고침한다.
  Future<List<LicenseKeyItem>> issueKeys(
    LicenseKeyCreatePayload payload,
  ) async {
    final created = await ref.read(licenseKeyRepositoryProvider).issueKeys(
          serviceType: serviceType,
          payload: payload,
        );
    _trackAction(
      'license_key_issue',
      parameters: {
        'key_type': payload.keyType.value,
        'count': created.length,
      },
    );
    await refreshAll();
    return created;
  }

  /// 시디키 메타데이터를 수정하고 목록을 새로고침한다.
  Future<void> updateKeyInfo(LicenseKeyUpdatePayload payload) async {
    await ref.read(licenseKeyRepositoryProvider).updateKeyInfo(
          serviceType: serviceType,
          payload: payload,
        );
    _trackAction(
      'license_key_update',
      parameters: {'key_type': payload.keyType.value},
    );
    await refreshAll();
  }

  /// 키를 사용 중지 또는 정상 재개 처리한다.
  Future<void> toggleReject(LicenseKeyItem item) async {
    final stop = !item.isStopped;
    await ref.read(licenseKeyRepositoryProvider).updateReject(
          serviceType: serviceType,
          key: item.key,
          stop: stop,
        );
    _trackAction(
      'license_key_reject_toggle',
      parameters: {'action_type': stop ? 'stop' : 'resume'},
    );
    await refreshAll();
  }

  /// 키에 연결된 단말기를 초기화한다.
  Future<void> initDevice(String key) async {
    await ref.read(licenseKeyRepositoryProvider).initDevice(
          serviceType: serviceType,
          key: key,
        );
    _trackAction('license_key_device_init');
    await refreshAll();
  }

  /// 키를 삭제한다.
  Future<void> deleteKey(String key) async {
    await ref.read(licenseKeyRepositoryProvider).deleteKey(
          serviceType: serviceType,
          key: key,
        );
    _trackAction('license_key_delete');
    if (state.page > 0 && state.items.length <= 1) {
      state = state.copyWith(page: state.page - 1);
    }
    await refreshAll();
  }

  /// 만료 기간이 경과한 키를 즉시 사용 중지 배치 점검한다.
  Future<int> runExpireBatch() async {
    state = state.copyWith(isBatchRunning: true);
    try {
      final count = await ref
          .read(licenseKeyRepositoryProvider)
          .expireBatch(serviceType);
      _trackAction(
        'license_key_expire_batch',
        parameters: {'expired_count': count},
      );
      await refreshAll();
      return count;
    } finally {
      state = state.copyWith(isBatchRunning: false);
    }
  }
}

/// 서비스 타입별 [LicenseKeyNotifier]를 제공하는 Riverpod Family Provider이다.
final licenseKeyProvider = NotifierProvider.family<LicenseKeyNotifier,
    LicenseKeyState, LicenseServiceType>(
  LicenseKeyNotifier.new,
);
