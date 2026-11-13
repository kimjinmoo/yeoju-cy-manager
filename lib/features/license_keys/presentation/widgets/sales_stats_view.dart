import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../providers/sales_stats_provider.dart';

/// 간편서명 및 MiniPos 최근 3개월 일별 판매(기기 인증) 통계를 네이티브 차트와 표로 보여주는 뷰이다.
class SalesStatsView extends ConsumerStatefulWidget {
  /// [SalesStatsView] 위젯을 생성한다.
  const SalesStatsView({super.key});

  @override
  ConsumerState<SalesStatsView> createState() => _SalesStatsViewState();
}

class _SalesStatsViewState extends ConsumerState<SalesStatsView> {
  bool _showSign = true;
  bool _showMiniPos = true;

  static final _numFmt = NumberFormat.decimalPattern('ko_KR');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesStatsProvider);
    final notifier = ref.read(salesStatsProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: EmptyStateView(
            icon: Icons.bar_chart_rounded,
            title: '판매 통계를 불러오지 못했습니다',
            description: state.errorMessage!,
            actionLabel: '다시 시도',
            onAction: notifier.loadStatistics,
          ),
        ),
      );
    }

    // 차트는 가독성을 위해 최근 21일 데이터를 표시한다.
    final recentChartPoints = state.points.length > 21
        ? state.points.sublist(state.points.length - 21)
        : state.points;
    final recentTablePoints = state.points.reversed.take(15).toList();

    return RefreshIndicator(
      onRefresh: notifier.loadStatistics,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            '판매 통계 (최근 3개월)',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '간편서명과 MiniPos(HO POS)의 단말기 인증 기준 일별 판매 현황입니다.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // 요약 KPI 3카드
          Row(
            children: [
              Expanded(
                child: _StatsKpiCard(
                  icon: Icons.trending_up_rounded,
                  label: '총 판매',
                  value: '${_numFmt.format(state.totalAll)}건',
                  valueColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatsKpiCard(
                  icon: Icons.draw_outlined,
                  label: '간편서명',
                  value: '${_numFmt.format(state.totalSign)}건',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatsKpiCard(
                  icon: Icons.point_of_sale_rounded,
                  label: 'MiniPos',
                  value: '${_numFmt.format(state.totalMiniPos)}건',
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 일별 추이 네이티브 바 차트 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '최근 21일 판매 추이',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _LegendToggle(
                        color: AppColors.primary,
                        label: '간편서명',
                        active: _showSign,
                        onTap: () => setState(() => _showSign = !_showSign),
                      ),
                      const SizedBox(width: 10),
                      _LegendToggle(
                        color: const Color(0xFF34C759),
                        label: 'MiniPos',
                        active: _showMiniPos,
                        onTap: () =>
                            setState(() => _showMiniPos = !_showMiniPos),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: recentChartPoints.isEmpty
                        ? const Center(
                            child: Text(
                              '표시할 통계 데이터가 없습니다.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : CustomPaint(
                            painter: _SalesBarChartPainter(
                              points: recentChartPoints,
                              showSign: _showSign,
                              showMiniPos: _showMiniPos,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '상세 내역 (최근 15일)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: AppColors.surfaceSubtle,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          '날짜',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '간편서명',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'MiniPos',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '합계',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final row in recentTablePoints)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            row.date,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${_numFmt.format(row.signCount)}건',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${_numFmt.format(row.miniPosCount)}건',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${_numFmt.format(row.totalCount)}건',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsKpiCard extends StatelessWidget {
  const _StatsKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendToggle extends StatelessWidget {
  const _LegendToggle({
    required this.color,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: active ? 1 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesBarChartPainter extends CustomPainter {
  _SalesBarChartPainter({
    required this.points,
    required this.showSign,
    required this.showMiniPos,
  });

  final List<CombinedDailySalesPoint> points;
  final bool showSign;
  final bool showMiniPos;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const bottomLabelHeight = 22.0;
    const leftPadding = 28.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomLabelHeight;

    var maxValue = 1;
    for (final p in points) {
      if (showSign) maxValue = math.max(maxValue, p.signCount);
      if (showMiniPos) maxValue = math.max(maxValue, p.miniPosCount);
    }

    final gridPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;

    // 3단계 가로 눈금선 및 Y축 최대값 표시
    for (var i = 0; i <= 2; i++) {
      final y = chartHeight - (chartHeight * (i / 2));
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );
      final tickVal = ((maxValue * i) / 2).round();
      final tp = TextPainter(
        text: TextSpan(
          text: '$tickVal',
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, (y - tp.height / 2).clamp(0, chartHeight)));
    }

    final slotWidth = chartWidth / points.length;
    final barWidth = (slotWidth * 0.34).clamp(3.0, 12.0);
    final signPaint = Paint()..color = AppColors.primary;
    final posPaint = Paint()..color = const Color(0xFF34C759);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final centerX = leftPadding + slotWidth * i + slotWidth / 2;

      if (showSign) {
        final h = (p.signCount / maxValue) * (chartHeight - 8);
        final left = showMiniPos ? centerX - barWidth - 1 : centerX - barWidth / 2;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, chartHeight - h, barWidth, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          signPaint,
        );
      }

      if (showMiniPos) {
        final h = (p.miniPosCount / maxValue) * (chartHeight - 8);
        final left = showSign ? centerX + 1 : centerX - barWidth / 2;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, chartHeight - h, barWidth, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          posPaint,
        );
      }

      // X축 날짜 라벨은 겹침 방지를 위해 일정 간격으로만 표시한다.
      final step = math.max(1, (points.length / 5).ceil());
      if (i == 0 || i == points.length - 1 || i % step == 0) {
        final shortDate = p.date.length >= 10 ? p.date.substring(5) : p.date;
        final tp = TextPainter(
          text: TextSpan(
            text: shortDate,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            (centerX - tp.width / 2).clamp(leftPadding, size.width - tp.width),
            chartHeight + 6,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.showSign != showSign ||
        oldDelegate.showMiniPos != showMiniPos;
  }
}
