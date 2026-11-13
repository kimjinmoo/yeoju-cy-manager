import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/license_key_models.dart';
import '../domain/license_service_type.dart';

/// MiniPos 및 간편서명(Sign) 라이선스 키 관리 API를 추상화한 저장소 인터페이스이다.
abstract class LicenseKeyRepository {
  /// 시디키 목록을 페이징하여 조회한다.
  Future<LicenseKeyPageResult> fetchKeys({
    required LicenseServiceType serviceType,
    required int page,
    required int size,
    String keyword = '',
    LicenseKeyStatusFilter status = LicenseKeyStatusFilter.all,
    LicenseKeyType? keyType,
    String salesLocation = '',
  });

  /// 상태별 요약 통계를 조회한다.
  Future<LicenseKeySummary> fetchSummary(LicenseServiceType serviceType);

  /// 등록된 고유 판매처 목록을 조회한다.
  Future<List<String>> fetchSalesLocations(LicenseServiceType serviceType);

  /// 시디키를 일괄 발급한다.
  Future<List<LicenseKeyItem>> issueKeys({
    required LicenseServiceType serviceType,
    required LicenseKeyCreatePayload payload,
  });

  /// 시디키 메타데이터를 수정한다.
  Future<LicenseKeyItem> updateKeyInfo({
    required LicenseServiceType serviceType,
    required LicenseKeyUpdatePayload payload,
  });

  /// 시디키 사용 중지(`Y`) 또는 정상 재개(`N`) 상태를 변경한다.
  Future<void> updateReject({
    required LicenseServiceType serviceType,
    required String key,
    required bool stop,
  });

  /// 시디키에 바인딩된 단말기 정보를 초기화한다.
  Future<void> initDevice({
    required LicenseServiceType serviceType,
    required String key,
  });

  /// 시디키를 영구 삭제한다.
  Future<void> deleteKey({
    required LicenseServiceType serviceType,
    required String key,
  });

  /// 만료 기간이 경과한 키를 즉시 사용 중지 배치 처리한다.
  Future<int> expireBatch(LicenseServiceType serviceType);

  /// 변경 이력 목록을 페이징하여 조회한다.
  Future<LicenseKeyHistoryPageResult> fetchHistories({
    required LicenseServiceType serviceType,
    String? key,
    String? actionType,
    String keyword = '',
    int page = 0,
    int size = 20,
  });

  /// 최근 3개월 일별 판매(기기 인증) 통계를 조회한다.
  Future<List<DailySalesStatItem>> fetchStatistics(
    LicenseServiceType serviceType,
  );
}

/// `grepiu_server`의 `/v1/mini-pos`, `/v1/sign` 엔드포인트와 통신하는 [LicenseKeyRepository] 구현체이다.
class GrepiuLicenseKeyRepository implements LicenseKeyRepository {
  /// [GrepiuLicenseKeyRepository] 인스턴스를 생성한다.
  GrepiuLicenseKeyRepository(this._dio);

  final Dio _dio;

  @override
  Future<LicenseKeyPageResult> fetchKeys({
    required LicenseServiceType serviceType,
    required int page,
    required int size,
    String keyword = '',
    LicenseKeyStatusFilter status = LicenseKeyStatusFilter.all,
    LicenseKeyType? keyType,
    String salesLocation = '',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        serviceType.basePath,
        queryParameters: {
          'page': page,
          'size': size,
          'status': status.value,
          if (keyword.trim().isNotEmpty) 'key': keyword.trim(),
          if (keyType != null) 'keyType': keyType.value,
          if (salesLocation.trim().isNotEmpty)
            'salesLocation': salesLocation.trim(),
        },
      );

      final body = response.data ?? const <String, dynamic>{};
      final rawList = body['data'] is List ? body['data'] as List : const [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(LicenseKeyItem.fromJson)
          .toList();
      final totalPages = (body['tpage'] as num?)?.toInt() ?? 1;
      final totalCount = (body['tcount'] as num?)?.toInt() ?? items.length;

      return LicenseKeyPageResult(
        items: items,
        totalPages: totalPages < 1 ? 1 : totalPages,
        totalCount: totalCount,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '시디키 목록을 불러오지 못했습니다.');
    }
  }

  @override
  Future<LicenseKeySummary> fetchSummary(LicenseServiceType serviceType) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${serviceType.basePath}/summary',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return LicenseKeySummary.fromJson(data);
      }
      return const LicenseKeySummary();
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '요약 통계를 불러오지 못했습니다.');
    }
  }

  @override
  Future<List<String>> fetchSalesLocations(
    LicenseServiceType serviceType,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${serviceType.basePath}/sales-locations',
      );
      final data = response.data?['data'];
      if (data is List) {
        return data.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '판매처 목록을 불러오지 못했습니다.');
    }
  }

  @override
  Future<List<LicenseKeyItem>> issueKeys({
    required LicenseServiceType serviceType,
    required LicenseKeyCreatePayload payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${serviceType.basePath}/issue',
        data: payload.toJson(),
      );
      final data = response.data?['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(LicenseKeyItem.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '시디키 발급에 실패했습니다.');
    }
  }

  @override
  Future<LicenseKeyItem> updateKeyInfo({
    required LicenseServiceType serviceType,
    required LicenseKeyUpdatePayload payload,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${serviceType.basePath}/info',
        data: payload.toJson(),
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return LicenseKeyItem.fromJson(data);
      }
      throw const ApiException(message: '수정된 키 정보를 확인할 수 없습니다.');
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '키 정보 수정에 실패했습니다.');
    }
  }

  @override
  Future<void> updateReject({
    required LicenseServiceType serviceType,
    required String key,
    required bool stop,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        '${serviceType.basePath}/reject',
        queryParameters: {'key': key, 'yn': stop ? 'Y' : 'N'},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(
        e,
        fallback: stop ? '사용 중지 처리에 실패했습니다.' : '정상 재개 처리에 실패했습니다.',
      );
    }
  }

  @override
  Future<void> initDevice({
    required LicenseServiceType serviceType,
    required String key,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${serviceType.basePath}/device-init',
        queryParameters: {'key': key},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '기기 연결 해제에 실패했습니다.');
    }
  }

  @override
  Future<void> deleteKey({
    required LicenseServiceType serviceType,
    required String key,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        serviceType.basePath,
        queryParameters: {'key': key},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '시디키 삭제에 실패했습니다.');
    }
  }

  @override
  Future<int> expireBatch(LicenseServiceType serviceType) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${serviceType.basePath}/expire-batch',
      );
      return (response.data?['data'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '만료 배치 실행에 실패했습니다.');
    }
  }

  @override
  Future<LicenseKeyHistoryPageResult> fetchHistories({
    required LicenseServiceType serviceType,
    String? key,
    String? actionType,
    String keyword = '',
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${serviceType.basePath}/history',
        queryParameters: {
          'page': page,
          'size': size,
          if (key != null && key.trim().isNotEmpty) 'key': key.trim(),
          if (actionType != null &&
              actionType.trim().isNotEmpty &&
              actionType != 'ALL')
            'actionType': actionType.trim(),
          if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        },
      );
      final body = response.data ?? const <String, dynamic>{};
      final rawList = body['data'] is List ? body['data'] as List : const [];
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(LicenseKeyHistoryItem.fromJson)
          .toList();
      final totalPages = (body['tpage'] as num?)?.toInt() ?? 1;
      final totalCount = (body['tcount'] as num?)?.toInt() ?? items.length;

      return LicenseKeyHistoryPageResult(
        items: items,
        totalPages: totalPages < 1 ? 1 : totalPages,
        totalCount: totalCount,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '변경 이력을 불러오지 못했습니다.');
    }
  }

  @override
  Future<List<DailySalesStatItem>> fetchStatistics(
    LicenseServiceType serviceType,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${serviceType.basePath}/statistics',
      );
      final data = response.data?['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(DailySalesStatItem.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e, fallback: '판매 통계를 불러오지 못했습니다.');
    }
  }
}

/// [LicenseKeyRepository]를 제공하는 Riverpod Provider이다.
final licenseKeyRepositoryProvider = Provider<LicenseKeyRepository>((ref) {
  return GrepiuLicenseKeyRepository(ref.watch(dioProvider));
});
