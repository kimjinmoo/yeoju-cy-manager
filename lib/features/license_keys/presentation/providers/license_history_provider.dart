import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/sandbox/review_sandbox.dart';
import '../../data/license_key_repository.dart';
import '../../domain/license_key_models.dart';
import '../../domain/license_service_type.dart';

/// 변경 이력 필터 항목 정의이다.
class HistoryActionFilterOption {
  /// [HistoryActionFilterOption] 인스턴스를 생성한다.
  const HistoryActionFilterOption({required this.id, required this.label});

  /// API 필터 ID
  final String id;

  /// UI 표시 라벨
  final String label;
}

/// 변경 이력 필터 프리셋 목록이다.
const List<HistoryActionFilterOption> historyActionFilters = [
  HistoryActionFilterOption(id: 'ALL', label: '전체 이력'),
  HistoryActionFilterOption(id: 'ISSUE', label: '발급'),
  HistoryActionFilterOption(id: 'UPDATE', label: '정보 수정'),
  HistoryActionFilterOption(id: 'ACTIVATE', label: '기기 인증'),
  HistoryActionFilterOption(id: 'DEVICE_INIT', label: '기기 해제'),
  HistoryActionFilterOption(id: 'STOP', label: '수동 중지'),
  HistoryActionFilterOption(id: 'RESUME', label: '정상 재개'),
  HistoryActionFilterOption(id: 'EXPIRE_BATCH', label: '배치 만료'),
  HistoryActionFilterOption(id: 'EXPIRE_AUTO', label: '인증시 만료'),
  HistoryActionFilterOption(id: 'DELETE', label: '삭제'),
];

/// 서비스별 변경 이력 탭 상태 모델이다.
@immutable
class LicenseHistoryState {
  /// [LicenseHistoryState] 인스턴스를 생성한다.
  const LicenseHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.actionFilter = 'ALL',
    this.keyword = '',
    this.page = 0,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 1,
    this.errorMessage,
  });

  /// 현재 페이지 이력 목록
  final List<LicenseKeyHistoryItem> items;

  /// 로딩 여부
  final bool isLoading;

  /// 변경 유형 필터
  final String actionFilter;

  /// 검색어
  final String keyword;

  /// 현재 페이지 (0-based)
  final int page;

  /// 페이지 크기
  final int pageSize;

  /// 전체 건수
  final int totalCount;

  /// 전체 페이지 수
  final int totalPages;

  /// 오류 메시지
  final String? errorMessage;

  /// 일부 필드를 갱신한 새 [LicenseHistoryState]를 반환한다.
  LicenseHistoryState copyWith({
    List<LicenseKeyHistoryItem>? items,
    bool? isLoading,
    String? actionFilter,
    String? keyword,
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LicenseHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      actionFilter: actionFilter ?? this.actionFilter,
      keyword: keyword ?? this.keyword,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 서비스별 시디키 변경 이력을 관리하는 Notifier이다.
class LicenseHistoryNotifier extends Notifier<LicenseHistoryState> {
  /// [LicenseHistoryNotifier] 인스턴스를 생성한다.
  LicenseHistoryNotifier(this.serviceType);

  /// 대상 서비스
  final LicenseServiceType serviceType;

  @override
  LicenseHistoryState build() {
    ref.watch(reviewSandboxProvider);
    Future.microtask(loadHistories);
    return const LicenseHistoryState(isLoading: true);
  }

  /// 변경 이력 목록을 조회한다.
  Future<void> loadHistories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(licenseKeyRepositoryProvider).fetchHistories(
            serviceType: serviceType,
            actionType: state.actionFilter == 'ALL' ? null : state.actionFilter,
            keyword: state.keyword,
            page: state.page,
            size: state.pageSize,
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
          fallback: '변경 이력을 불러오지 못했습니다.',
        ),
      );
    }
  }

  /// 변경 유형 필터를 변경한다.
  Future<void> setActionFilter(String actionId) async {
    state = state.copyWith(actionFilter: actionId, page: 0);
    await loadHistories();
  }

  /// 검색어를 변경한다.
  Future<void> setKeyword(String keyword) async {
    final normalized = keyword.trim();
    if (normalized == state.keyword) return;
    state = state.copyWith(keyword: normalized, page: 0);
    await loadHistories();
  }

  /// 페이지를 이동한다.
  Future<void> goToPage(int nextPage) async {
    if (nextPage < 0 || nextPage >= state.totalPages || nextPage == state.page) {
      return;
    }
    state = state.copyWith(page: nextPage);
    await loadHistories();
  }

  /// 페이지 크기를 변경한다.
  Future<void> setPageSize(int nextSize) async {
    state = state.copyWith(pageSize: nextSize, page: 0);
    await loadHistories();
  }
}

/// 서비스 타입별 [LicenseHistoryNotifier]를 제공하는 Riverpod Family Provider이다.
final licenseHistoryProvider = NotifierProvider.family<LicenseHistoryNotifier,
    LicenseHistoryState, LicenseServiceType>(
  LicenseHistoryNotifier.new,
);
