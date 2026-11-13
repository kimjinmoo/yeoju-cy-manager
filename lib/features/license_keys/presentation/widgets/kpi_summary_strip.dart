import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/license_key_models.dart';

/// 시디키 상태별 KPI 요약 카드 스트립 위젯이다.
class KpiSummaryStrip extends StatelessWidget {
  /// [KpiSummaryStrip] 위젯을 생성한다.
  const KpiSummaryStrip({
    super.key,
    required this.summary,
    required this.activeFilter,
    required this.onSelectFilter,
  });

  /// 요약 통계 데이터
  final LicenseKeySummary summary;

  /// 현재 선택된 상태 필터
  final LicenseKeyStatusFilter activeFilter;

  /// 카드 탭 시 상태 필터 변경 콜백
  final ValueChanged<LicenseKeyStatusFilter> onSelectFilter;

  static final _numFmt = NumberFormat.decimalPattern('ko_KR');

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCardData(
        filter: LicenseKeyStatusFilter.all,
        label: '전체 시디키',
        value: _numFmt.format(summary.total),
        subLabel:
            '판매 ${_numFmt.format(summary.saleCount)} · 테스트 ${_numFmt.format(summary.testCount)}',
        valueColor: AppColors.textPrimary,
      ),
      _KpiCardData(
        filter: LicenseKeyStatusFilter.unused,
        label: '사용 대기',
        value: _numFmt.format(summary.unused),
        subLabel: '발급 완료 · 미등록',
        valueColor: AppColors.textPrimary,
      ),
      _KpiCardData(
        filter: LicenseKeyStatusFilter.active,
        label: '사용중 (인증완료)',
        value: _numFmt.format(summary.active),
        subLabel: '단말기 바인딩 정상',
        valueColor: AppColors.success,
      ),
      _KpiCardData(
        filter: LicenseKeyStatusFilter.expiringSoon,
        label: '만료 임박 (7일 내)',
        value: _numFmt.format(summary.expiringSoon),
        subLabel: '기간 연장 확인 필요',
        valueColor:
            summary.expiringSoon > 0 ? AppColors.warning : AppColors.textPrimary,
        isWarning: summary.expiringSoon > 0,
      ),
      _KpiCardData(
        filter: LicenseKeyStatusFilter.stopped,
        label: '사용 중지 / 만료',
        value: _numFmt.format(summary.stopped),
        subLabel: '기간 만료 ${_numFmt.format(summary.expired)}건 포함',
        valueColor:
            summary.stopped > 0 ? AppColors.danger : AppColors.textPrimary,
      ),
    ];

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = cards[index];
          final isSelected = activeFilter == item.filter;
          final borderColor = isSelected
              ? (item.isWarning ? const Color(0xFFFF9500) : AppColors.primary)
              : (item.isWarning
                  ? const Color(0xFFFFE2B3)
                  : AppColors.borderSubtle);
          final bgColor = isSelected
              ? AppColors.surface
              : (item.isWarning ? AppColors.warningBg : AppColors.surfaceSubtle);

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelectFilter(item.filter),
            child: Container(
              width: 164,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 1.6 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (item.isWarning
                                  ? const Color(0xFFFF9500)
                                  : AppColors.primary)
                              .withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: item.valueColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    item.subLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.filter,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.valueColor,
    this.isWarning = false,
  });

  final LicenseKeyStatusFilter filter;
  final String label;
  final String value;
  final String subLabel;
  final Color valueColor;
  final bool isWarning;
}
