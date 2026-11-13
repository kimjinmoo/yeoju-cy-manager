import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';

/// 시디키 목록과 변경 이력 목록에서 공용으로 사용하는 하단 페이징 바 위젯이다.
class PaginationBar extends StatelessWidget {
  /// [PaginationBar] 위젯을 생성한다.
  const PaginationBar({
    super.key,
    required this.label,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  /// 건수 안내 접두어 (예: `검색 결과 총`, `변경 이력 총`)
  final String label;

  /// 전체 건수
  final int totalCount;

  /// 현재 페이지 (0-based)
  final int currentPage;

  /// 총 페이지 수
  final int totalPages;

  /// 페이지 이동 콜백
  final ValueChanged<int> onPageSelected;

  static final _numFmt = NumberFormat.decimalPattern('ko_KR');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$label ${_numFmt.format(totalCount)}건'
            '${totalPages > 1 ? ' · ${currentPage + 1} / $totalPages 페이지' : ''}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: currentPage > 0
                      ? () => onPageSelected(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '이전 페이지',
                ),
                ..._buildPageWindow(currentPage, totalPages).map((idx) {
                  final active = idx == currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onPageSelected(idx),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color:
                                active ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                IconButton(
                  onPressed: currentPage < totalPages - 1
                      ? () => onPageSelected(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 페이지',
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<int> _buildPageWindow(int current, int total) {
    const maxButtons = 5;
    if (total <= maxButtons) {
      return List.generate(total, (i) => i);
    }
    const half = maxButtons ~/ 2;
    var start = (current - half).clamp(0, total - 1);
    final end = (start + maxButtons - 1).clamp(0, total - 1);
    if (end - start + 1 < maxButtons) {
      start = (end - maxButtons + 1).clamp(0, total - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }
}
