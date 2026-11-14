import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/sandbox/review_sandbox.dart';
import '../../data/license_key_repository.dart';
import '../../domain/license_service_type.dart';

/// 일별 통합 판매(MiniPos + 간편서명) 추이 차트 항목이다.
@immutable
class CombinedDailySalesPoint {
  /// [CombinedDailySalesPoint] 인스턴스를 생성한다.
  const CombinedDailySalesPoint({
    required this.date,
    required this.signCount,
    required this.miniPosCount,
  });

  /// 날짜 (`YYYY-MM-dd`)
  final String date;

  /// 간편서명 건수
  final int signCount;

  /// MiniPos 건수
  final int miniPosCount;

  /// 일자 합계
  int get totalCount => signCount + miniPosCount;
}

/// 최근 3개월 판매 통계 상태 모델이다.
@immutable
class SalesStatsState {
  /// [SalesStatsState] 인스턴스를 생성한다.
  const SalesStatsState({
    this.points = const [],
    this.totalSign = 0,
    this.totalMiniPos = 0,
    this.isLoading = true,
    this.errorMessage,
  });

  /// 일자별 오름차순 포인트 목록
  final List<CombinedDailySalesPoint> points;

  /// 간편서명 누적 건수
  final int totalSign;

  /// MiniPos 누적 건수
  final int totalMiniPos;

  /// 로딩 중 여부
  final bool isLoading;

  /// 오류 메시지
  final String? errorMessage;

  /// 전체 합계 건수
  int get totalAll => totalSign + totalMiniPos;

  /// 일부 필드를 갱신한 새 [SalesStatsState]를 반환한다.
  SalesStatsState copyWith({
    List<CombinedDailySalesPoint>? points,
    int? totalSign,
    int? totalMiniPos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SalesStatsState(
      points: points ?? this.points,
      totalSign: totalSign ?? this.totalSign,
      totalMiniPos: totalMiniPos ?? this.totalMiniPos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// MiniPos 및 간편서명 최근 3개월 판매 통계를 조회·병합하는 Notifier이다.
class SalesStatsNotifier extends Notifier<SalesStatsState> {
  @override
  SalesStatsState build() {
    ref.watch(reviewSandboxProvider);
    Future.microtask(loadStatistics);
    return const SalesStatsState();
  }

  /// MiniPos와 간편서명 통계를 병렬로 조회하여 일자별로 병합한다.
  Future<void> loadStatistics() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(licenseKeyRepositoryProvider);

    try {
      final results = await Future.wait([
        repo.fetchStatistics(LicenseServiceType.sign),
        repo.fetchStatistics(LicenseServiceType.miniPos),
      ]);

      final signList = results[0];
      final posList = results[1];

      final map = <String, ({int sign, int pos})>{};
      var totalSign = 0;
      var totalPos = 0;

      for (final item in signList) {
        totalSign += item.count;
        final prev = map[item.date];
        map[item.date] = (sign: item.count, pos: prev?.pos ?? 0);
      }

      for (final item in posList) {
        totalPos += item.count;
        final prev = map[item.date];
        map[item.date] = (sign: prev?.sign ?? 0, pos: item.count);
      }

      final dates = map.keys.toList()..sort();
      final points = dates
          .map(
            (date) => CombinedDailySalesPoint(
              date: date,
              signCount: map[date]!.sign,
              miniPosCount: map[date]!.pos,
            ),
          )
          .toList();

      state = state.copyWith(
        points: points,
        totalSign: totalSign,
        totalMiniPos: totalPos,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: extractErrorMessage(
          error,
          fallback: '판매 통계를 불러오지 못했습니다.',
        ),
      );
    }
  }
}

/// 판매 통계 상태를 제공하는 Riverpod Provider이다.
final salesStatsProvider =
    NotifierProvider<SalesStatsNotifier, SalesStatsState>(
  SalesStatsNotifier.new,
);
