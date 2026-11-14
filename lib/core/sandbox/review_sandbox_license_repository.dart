import 'dart:math' as math;

import '../../features/license_keys/data/license_key_repository.dart';
import '../../features/license_keys/domain/license_key_models.dart';
import '../../features/license_keys/domain/license_service_type.dart';
import 'review_sandbox.dart';

/// 스토어 심사 테스트 계정(`test`) 로그인 시 동작하는 로컬 인메모리 [LicenseKeyRepository] 구현체이다.
///
/// 실제 운영 서버에 어떠한 API 요청도 보내지 않으며,
/// 목록 조회·필터링·발급·수정·중지/재개·기기초기화·삭제·이력·통계를 로컬 목업 데이터로 완결 처리한다.
class ReviewSandboxLicenseKeyRepository implements LicenseKeyRepository {
  /// [ReviewSandboxLicenseKeyRepository] 인스턴스를 생성한다.
  ReviewSandboxLicenseKeyRepository(this._store);

  final ReviewSandboxStore _store;

  bool _isExpired(LicenseKeyItem item, DateTime now) {
    if (item.rejectReason == 'EXPIRED') return true;
    final raw = item.expireDate;
    if (raw == null || raw.trim().isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    return parsed != null && parsed.isBefore(now);
  }

  bool _isExpiringSoon(LicenseKeyItem item, DateTime now) {
    if (item.isStopped || _isExpired(item, now)) return false;
    final raw = item.expireDate;
    if (raw == null || raw.trim().isEmpty) return false;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    return !parsed.isBefore(now) && parsed.difference(now).inDays <= 7;
  }

  String _serviceCode(LicenseServiceType serviceType) =>
      serviceType == LicenseServiceType.miniPos ? 'MINI_POS' : 'SIGN';

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
    final kw = keyword.trim().toLowerCase();
    final loc = salesLocation.trim();
    final now = DateTime.now();

    final filtered = _store.keysFor(serviceType).where((item) {
      if (kw.isNotEmpty) {
        final matched = item.key.toLowerCase().contains(kw) ||
            (item.salesLocation?.toLowerCase().contains(kw) ?? false) ||
            (item.device?.toLowerCase().contains(kw) ?? false) ||
            (item.memo?.toLowerCase().contains(kw) ?? false);
        if (!matched) return false;
      }

      if (keyType != null &&
          (item.keyType ?? '').trim().toUpperCase() != keyType.value) {
        return false;
      }

      if (loc == emptySalesLocationToken) {
        if (item.salesLocation != null &&
            item.salesLocation!.trim().isNotEmpty) {
          return false;
        }
      } else if (loc.isNotEmpty && (item.salesLocation ?? '').trim() != loc) {
        return false;
      }

      final expired = _isExpired(item, now);
      switch (status) {
        case LicenseKeyStatusFilter.all:
          return true;
        case LicenseKeyStatusFilter.unused:
          return !item.isStopped && !item.hasDevice && !expired;
        case LicenseKeyStatusFilter.active:
          return !item.isStopped && item.hasDevice && !expired;
        case LicenseKeyStatusFilter.expiringSoon:
          return _isExpiringSoon(item, now);
        case LicenseKeyStatusFilter.stopped:
          return item.isStopped;
        case LicenseKeyStatusFilter.expired:
          return expired;
      }
    }).toList();

    final totalCount = filtered.length;
    final totalPages = math.max(1, (totalCount / size).ceil());
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * size;
    final end = math.min(totalCount, start + size);

    return LicenseKeyPageResult(
      items: start < totalCount ? filtered.sublist(start, end) : const [],
      totalPages: totalPages,
      totalCount: totalCount,
    );
  }

  @override
  Future<LicenseKeySummary> fetchSummary(
    LicenseServiceType serviceType,
  ) async {
    final list = _store.keysFor(serviceType);
    final now = DateTime.now();
    var active = 0;
    var unused = 0;
    var stopped = 0;
    var expired = 0;
    var expiringSoon = 0;
    var saleCount = 0;
    var testCount = 0;

    for (final item in list) {
      if (item.isTestKey) {
        testCount++;
      } else {
        saleCount++;
      }
      final itemExpired = _isExpired(item, now);
      if (itemExpired) expired++;
      if (item.isStopped) {
        stopped++;
      } else if (!itemExpired) {
        if (item.hasDevice) {
          active++;
        } else {
          unused++;
        }
        if (_isExpiringSoon(item, now)) expiringSoon++;
      }
    }

    return LicenseKeySummary(
      total: list.length,
      active: active,
      unused: unused,
      stopped: stopped,
      expired: expired,
      expiringSoon: expiringSoon,
      saleCount: saleCount,
      testCount: testCount,
    );
  }

  @override
  Future<List<String>> fetchSalesLocations(
    LicenseServiceType serviceType,
  ) async {
    final locations = _store
        .keysFor(serviceType)
        .map((e) => (e.salesLocation ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return locations;
  }

  @override
  Future<List<LicenseKeyItem>> issueKeys({
    required LicenseServiceType serviceType,
    required LicenseKeyCreatePayload payload,
  }) async {
    final prefix = serviceType == LicenseServiceType.miniPos ? 'MPOS' : 'SIGN';
    final created = <LicenseKeyItem>[];
    final list = _store.keysFor(serviceType);
    final nowIso = DateTime.now().toIso8601String();

    for (var i = 0; i < payload.count; i++) {
      final seq = _store.nextSeq().toString().padLeft(4, '0');
      final item = LicenseKeyItem(
        key: 'DEMO-$prefix-$seq-TEST',
        reject: 'N',
        keyType: payload.keyType.value,
        salesLocation: payload.salesLocation.isEmpty
            ? '심사 테스트'
            : payload.salesLocation,
        validDays: payload.validDays,
        createDate: nowIso,
        memo: payload.memo.isEmpty ? null : payload.memo,
      );
      list.insert(0, item);
      created.add(item);

      _store.historiesFor(serviceType).insert(
        0,
        LicenseKeyHistoryItem(
          id: 'demo-hist-${_store.nextSeq()}',
          serviceType: _serviceCode(serviceType),
          key: item.key,
          actionType: 'ISSUE',
          summary: '신규 발급 (심사 테스트)',
          changedBy: ReviewSandboxConfig.reviewUser.email,
          changedAt: nowIso,
          afterData: {
            'keyType': item.keyType,
            'salesLocation': item.salesLocation,
            'validDays': item.validDays,
            if (item.memo != null) 'memo': item.memo,
          },
        ),
      );
    }

    return created;
  }

  @override
  Future<LicenseKeyItem> updateKeyInfo({
    required LicenseServiceType serviceType,
    required LicenseKeyUpdatePayload payload,
  }) async {
    final list = _store.keysFor(serviceType);
    final index = list.indexWhere((e) => e.key == payload.key);
    final current = index >= 0 ? list[index] : LicenseKeyItem(key: payload.key);
    final now = DateTime.now();

    final updated = LicenseKeyItem(
      key: current.key,
      device: current.device,
      reject: payload.reactivate ? 'N' : current.reject,
      rejectReason: payload.reactivate ? null : current.rejectReason,
      keyType: payload.keyType.value,
      salesLocation: payload.salesLocation,
      validDays: payload.validDays,
      expireDate: payload.validDays == 0
          ? null
          : (payload.recalculateExpire || current.expireDate == null
              ? now
                  .add(Duration(days: payload.validDays))
                  .toIso8601String()
              : current.expireDate),
      activatedDate: current.activatedDate,
      createDate: current.createDate,
      updateDate: now.toIso8601String(),
      memo: payload.memo,
    );

    if (index >= 0) {
      list[index] = updated;
    }

    _store.historiesFor(serviceType).insert(
      0,
      LicenseKeyHistoryItem(
        id: 'demo-hist-${_store.nextSeq()}',
        serviceType: _serviceCode(serviceType),
        key: updated.key,
        actionType: 'UPDATE',
        summary: '키 정보 수정',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: now.toIso8601String(),
        beforeData: {
          'keyType': current.keyType,
          'salesLocation': current.salesLocation,
          'validDays': current.validDays,
          'expireDate': current.expireDate,
          'memo': current.memo,
          'reject': current.reject,
          'rejectReason': current.rejectReason,
        },
        afterData: {
          'keyType': updated.keyType,
          'salesLocation': updated.salesLocation,
          'validDays': updated.validDays,
          'expireDate': updated.expireDate,
          'memo': updated.memo,
          'reject': updated.reject,
          'rejectReason': updated.rejectReason,
        },
      ),
    );

    return updated;
  }

  @override
  Future<void> updateReject({
    required LicenseServiceType serviceType,
    required String key,
    required bool stop,
  }) async {
    final list = _store.keysFor(serviceType);
    final index = list.indexWhere((e) => e.key == key);
    if (index < 0) return;

    final current = list[index];
    final nowIso = DateTime.now().toIso8601String();
    final nextReason = stop ? 'MANUAL' : null;
    list[index] = LicenseKeyItem(
      key: current.key,
      device: current.device,
      reject: stop ? 'Y' : 'N',
      rejectReason: nextReason,
      keyType: current.keyType,
      salesLocation: current.salesLocation,
      validDays: current.validDays,
      expireDate: current.expireDate,
      activatedDate: current.activatedDate,
      createDate: current.createDate,
      updateDate: nowIso,
      memo: current.memo,
    );

    _store.historiesFor(serviceType).insert(
      0,
      LicenseKeyHistoryItem(
        id: 'demo-hist-${_store.nextSeq()}',
        serviceType: _serviceCode(serviceType),
        key: key,
        actionType: stop ? 'STOP' : 'RESUME',
        summary: stop ? '사용 중지' : '정상 재개',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: nowIso,
        beforeData: {
          'reject': current.reject,
          'rejectReason': current.rejectReason,
          'device': current.device,
        },
        afterData: {
          'reject': stop ? 'Y' : 'N',
          'rejectReason': nextReason,
          'device': current.device,
        },
      ),
    );
  }

  @override
  Future<void> initDevice({
    required LicenseServiceType serviceType,
    required String key,
  }) async {
    final list = _store.keysFor(serviceType);
    final index = list.indexWhere((e) => e.key == key);
    if (index < 0) return;

    final current = list[index];
    final nowIso = DateTime.now().toIso8601String();
    list[index] = LicenseKeyItem(
      key: current.key,
      device: null,
      reject: current.reject,
      rejectReason: current.rejectReason,
      keyType: current.keyType,
      salesLocation: current.salesLocation,
      validDays: current.validDays,
      expireDate: current.expireDate,
      activatedDate: null,
      createDate: current.createDate,
      updateDate: nowIso,
      memo: current.memo,
    );

    _store.historiesFor(serviceType).insert(
      0,
      LicenseKeyHistoryItem(
        id: 'demo-hist-${_store.nextSeq()}',
        serviceType: _serviceCode(serviceType),
        key: key,
        actionType: 'DEVICE_INIT',
        summary: '기기 연결 해제',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: nowIso,
        beforeData: {'device': current.device},
        afterData: const {'device': ''},
      ),
    );
  }

  @override
  Future<void> deleteKey({
    required LicenseServiceType serviceType,
    required String key,
  }) async {
    final list = _store.keysFor(serviceType);
    final index = list.indexWhere((e) => e.key == key);
    final current = index >= 0 ? list[index] : null;
    list.removeWhere((e) => e.key == key);

    _store.historiesFor(serviceType).insert(
      0,
      LicenseKeyHistoryItem(
        id: 'demo-hist-${_store.nextSeq()}',
        serviceType: _serviceCode(serviceType),
        key: key,
        actionType: 'DELETE',
        summary: '시디키 삭제',
        changedBy: ReviewSandboxConfig.reviewUser.email,
        changedAt: DateTime.now().toIso8601String(),
        beforeData: current == null
            ? null
            : {
                'keyType': current.keyType,
                'reject': current.reject,
                'rejectReason': current.rejectReason,
                'device': current.device,
              },
      ),
    );
  }

  @override
  Future<int> expireBatch(LicenseServiceType serviceType) async {
    final list = _store.keysFor(serviceType);
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    var count = 0;

    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (!item.isStopped && _isExpired(item, now)) {
        list[i] = LicenseKeyItem(
          key: item.key,
          device: item.device,
          reject: 'Y',
          rejectReason: 'EXPIRED',
          keyType: item.keyType,
          salesLocation: item.salesLocation,
          validDays: item.validDays,
          expireDate: item.expireDate,
          activatedDate: item.activatedDate,
          memo: item.memo,
          createDate: item.createDate,
          updateDate: nowIso,
        );
        _store.historiesFor(serviceType).insert(
          0,
          LicenseKeyHistoryItem(
            id: 'demo-hist-${_store.nextSeq()}',
            serviceType: _serviceCode(serviceType),
            key: item.key,
            actionType: 'EXPIRE_BATCH',
            summary: '만료 배치 점검으로 사용 중지',
            changedBy: ReviewSandboxConfig.reviewUser.email,
            changedAt: nowIso,
            beforeData: {
              'reject': item.reject,
              'device': item.device,
            },
            afterData: {
              'reject': 'Y',
              'rejectReason': 'EXPIRED',
              'device': item.device,
            },
          ),
        );
        count++;
      }
    }
    return count;
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
    final kw = keyword.trim().toLowerCase();
    final targetKey = key?.trim();

    final filtered = _store.historiesFor(serviceType).where((item) {
      if (targetKey != null && targetKey.isNotEmpty && item.key != targetKey) {
        return false;
      }
      if (actionType != null &&
          actionType.trim().isNotEmpty &&
          actionType != 'ALL' &&
          item.actionType != actionType) {
        return false;
      }
      if (kw.isNotEmpty) {
        final matched = item.key.toLowerCase().contains(kw) ||
            (item.summary?.toLowerCase().contains(kw) ?? false) ||
            (item.changedBy?.toLowerCase().contains(kw) ?? false);
        if (!matched) return false;
      }
      return true;
    }).toList();

    final totalCount = filtered.length;
    final totalPages = math.max(1, (totalCount / size).ceil());
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * size;
    final end = math.min(totalCount, start + size);

    return LicenseKeyHistoryPageResult(
      items: start < totalCount ? filtered.sublist(start, end) : const [],
      totalPages: totalPages,
      totalCount: totalCount,
    );
  }

  @override
  Future<List<DailySalesStatItem>> fetchStatistics(
    LicenseServiceType serviceType,
  ) async {
    final now = DateTime.now();
    // 최근 30일간 심사용 일별 판매 추이 목업 데이터
    final counts = serviceType == LicenseServiceType.miniPos
        ? const [
            2, 3, 4, 2, 5, 6, 4, 3, 5, 4,
            3, 6, 7, 5, 4, 3, 5, 4, 6, 5,
            4, 3, 5, 6, 4, 5, 4, 7, 5, 3,
          ]
        : const [
            1, 2, 2, 1, 3, 4, 2, 2, 3, 2,
            2, 3, 4, 3, 2, 1, 3, 2, 4, 3,
            2, 2, 3, 4, 2, 3, 3, 5, 3, 2,
          ];

    return List.generate(counts.length, (index) {
      final d = now.subtract(Duration(days: (counts.length - 1) - index));
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return DailySalesStatItem(
        date: '${d.year}-$mm-$dd',
        count: counts[index],
      );
    });
  }
}
