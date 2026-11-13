import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 변경 이력 액션 유형에 대응하는 라벨 및 색상 메타데이터이다.
class HistoryActionMeta {
  /// [HistoryActionMeta] 인스턴스를 생성한다.
  const HistoryActionMeta({
    required this.label,
    required this.foreground,
    required this.background,
  });

  /// 한글 라벨
  final String label;

  /// 글자/아이콘 색상
  final Color foreground;

  /// 배지 배경 색상
  final Color background;
}

/// 변경 전·후 스냅샷 비교 diff 항목이다.
class SnapshotDiffEntry {
  /// [SnapshotDiffEntry] 인스턴스를 생성한다.
  const SnapshotDiffEntry({
    required this.label,
    this.before,
    required this.after,
  });

  /// 필드명
  final String label;

  /// 이전 값 (신규 발급 등에서는 null)
  final String? before;

  /// 변경 후 값
  final String after;
}

/// 변경 이력 액션 메타데이터 및 스냅샷 diff 생성 헬퍼이다.
abstract final class HistoryDiffHelper {
  /// 액션 코드에 대응하는 배지 메타데이터를 반환한다.
  static HistoryActionMeta resolveActionMeta(String? actionType) {
    switch (actionType) {
      case 'ISSUE':
        return HistoryActionMeta(
          label: '키 발급',
          foreground: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.1),
        );
      case 'UPDATE':
        return HistoryActionMeta(
          label: '정보 수정',
          foreground: const Color(0xFF5856D6),
          background: const Color(0xFF5856D6).withValues(alpha: 0.1),
        );
      case 'ACTIVATE':
        return HistoryActionMeta(
          label: '기기 인증',
          foreground: AppColors.success,
          background: AppColors.success.withValues(alpha: 0.14),
        );
      case 'DEVICE_INIT':
        return HistoryActionMeta(
          label: '기기 해제',
          foreground: AppColors.warning,
          background: const Color(0xFFFF9500).withValues(alpha: 0.14),
        );
      case 'STOP':
        return HistoryActionMeta(
          label: '수동 중지',
          foreground: AppColors.danger,
          background: AppColors.danger.withValues(alpha: 0.12),
        );
      case 'RESUME':
        return HistoryActionMeta(
          label: '정상 재개',
          foreground: AppColors.success,
          background: AppColors.success.withValues(alpha: 0.14),
        );
      case 'EXPIRE_BATCH':
        return HistoryActionMeta(
          label: '배치 만료',
          foreground: AppColors.danger,
          background: AppColors.danger.withValues(alpha: 0.12),
        );
      case 'EXPIRE_AUTO':
        return HistoryActionMeta(
          label: '인증시 만료',
          foreground: AppColors.danger,
          background: AppColors.danger.withValues(alpha: 0.12),
        );
      case 'DELETE':
        return HistoryActionMeta(
          label: '키 삭제',
          foreground: AppColors.danger,
          background: AppColors.danger.withValues(alpha: 0.12),
        );
      default:
        return HistoryActionMeta(
          label: (actionType != null && actionType.isNotEmpty)
              ? actionType
              : '변경',
          foreground: const Color(0xFF5856D6),
          background: const Color(0xFF5856D6).withValues(alpha: 0.1),
        );
    }
  }

  /// `beforeData`와 `afterData`를 비교해 화면 표시용 diff 목록을 생성한다.
  static List<SnapshotDiffEntry> buildDiffs(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    if (before == null && after == null) return const [];
    final diffs = <SnapshotDiffEntry>[];

    if (before == null && after != null) {
      diffs.add(
        SnapshotDiffEntry(
          label: '구분',
          after: after['keyType'] == 'TEST' ? '테스트키' : '판매키',
        ),
      );
      final location = _str(after['salesLocation']);
      if (location.isNotEmpty) {
        diffs.add(SnapshotDiffEntry(label: '판매처', after: location));
      }
      diffs.add(SnapshotDiffEntry(label: '기간', after: _formatPeriod(after)));
      final memo = _str(after['memo']);
      if (memo.isNotEmpty) {
        diffs.add(SnapshotDiffEntry(label: '비고', after: memo));
      }
      return diffs;
    }

    if (before != null && after == null) {
      diffs.add(
        SnapshotDiffEntry(
          label: '삭제 전 상태',
          after:
              '${before['keyType'] == 'TEST' ? '테스트키' : '판매키'} · ${_formatStatus(before)}',
        ),
      );
      return diffs;
    }

    if (before != null && after != null) {
      final bType = before['keyType'] == 'TEST' ? '테스트키' : '판매키';
      final aType = after['keyType'] == 'TEST' ? '테스트키' : '판매키';
      if (bType != aType) {
        diffs.add(SnapshotDiffEntry(label: '구분', before: bType, after: aType));
      }

      final bLoc = _strOr(before['salesLocation'], '미입력');
      final aLoc = _strOr(after['salesLocation'], '미입력');
      if (bLoc != aLoc) {
        diffs.add(SnapshotDiffEntry(label: '판매처', before: bLoc, after: aLoc));
      }

      final bPeriod = _formatPeriod(before);
      final aPeriod = _formatPeriod(after);
      if (bPeriod != aPeriod) {
        diffs.add(
          SnapshotDiffEntry(label: '기간', before: bPeriod, after: aPeriod),
        );
      }

      final bDev = _strOr(before['device'], '미연결');
      final aDev = _strOr(after['device'], '미연결');
      if (bDev != aDev) {
        diffs.add(SnapshotDiffEntry(label: '기기', before: bDev, after: aDev));
      }

      final bStatus = _formatStatus(before);
      final aStatus = _formatStatus(after);
      if (bStatus != aStatus) {
        diffs.add(
          SnapshotDiffEntry(label: '상태', before: bStatus, after: aStatus),
        );
      }

      final bMemo = _str(before['memo']);
      final aMemo = _str(after['memo']);
      if (bMemo != aMemo) {
        diffs.add(
          SnapshotDiffEntry(
            label: '비고',
            before: bMemo.isEmpty ? '없음' : bMemo,
            after: aMemo.isEmpty ? '없음' : aMemo,
          ),
        );
      }
    }

    return diffs;
  }

  static String _formatPeriod(Map<String, dynamic> snap) {
    final days = (snap['validDays'] as num?)?.toInt() ?? 0;
    if (days <= 0) return '영구적(0일)';
    final exp = _str(snap['expireDate']);
    return exp.isNotEmpty ? '$days일 (~$exp)' : '$days일';
  }

  static String _formatStatus(Map<String, dynamic> snap) {
    if (snap['reject'] == 'Y') {
      return snap['rejectReason'] == 'EXPIRED' ? '기간 만료 중지' : '사용 중지';
    }
    return _str(snap['device']).isNotEmpty ? '사용중' : '정상(대기)';
  }

  static String _str(Object? val) => val == null ? '' : val.toString().trim();

  static String _strOr(Object? val, String fallback) {
    final s = _str(val);
    return s.isEmpty ? fallback : s;
  }
}
