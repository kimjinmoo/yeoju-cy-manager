import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../domain/license_service_type.dart';
import '../providers/license_history_provider.dart';
import '../utils/history_diff_helper.dart';
import 'key_history_sheet.dart';

/// 서비스 전체 시디키 변경 이력을 필터링·조회하는 탭 뷰 위젯이다.
class HistoryListView extends ConsumerStatefulWidget {
  /// [HistoryListView] 위젯을 생성한다.
  const HistoryListView({super.key, required this.serviceType});

  /// 대상 서비스 타입
  final LicenseServiceType serviceType;

  @override
  ConsumerState<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends ConsumerState<HistoryListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref
          .read(licenseHistoryProvider(widget.serviceType).notifier)
          .setKeyword(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref
        .read(licenseHistoryProvider(widget.serviceType).notifier)
        .setKeyword('');
  }

  void _openKeyTimeline(String key) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => KeyHistorySheet(
        serviceType: widget.serviceType,
        targetKey: key,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(licenseHistoryProvider(widget.serviceType));
    final notifier = ref.read(licenseHistoryProvider(widget.serviceType).notifier);

    return RefreshIndicator(
      onRefresh: notifier.loadHistories,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: notifier.setKeyword,
                  decoration: InputDecoration(
                    hintText: '시디키, 변경 요약, 작업자로 검색...',
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close, size: 17),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: historyActionFilters.map((filter) {
                      final selected = state.actionFilter == filter.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            filter.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.textPrimary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.border,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => notifier.setActionFilter(filter.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null)
            EmptyStateView(
              icon: Icons.error_outline,
              title: '변경 이력을 불러오지 못했습니다',
              description: state.errorMessage!,
              actionLabel: '다시 시도',
              onAction: notifier.loadHistories,
            )
          else if (state.items.isEmpty)
            const EmptyStateView(
              icon: Icons.history_rounded,
              title: '기록된 변경 이력이 없습니다',
              description:
                  '시디키 발급, 정보 수정, 기기 인증/해제, 사용 중지 및 만료 처리 시 이력이 자동 기록됩니다.',
            )
          else ...[
            ...state.items.map((item) {
              final meta = HistoryDiffHelper.resolveActionMeta(item.actionType);
              final diffs = HistoryDiffHelper.buildDiffs(
                item.beforeData,
                item.afterData,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HistoryActionBadge(meta: meta),
                            const Spacer(),
                            Text(
                              DateFormatter.formatDateTime(item.changedAt),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: item.key),
                                );
                                if (context.mounted) {
                                  AppFeedback.showSuccess(
                                    context,
                                    '${item.key} 복사 완료',
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.key,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.copy_rounded,
                                      size: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.person_outline,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.changedBy ?? 'SYSTEM',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.summary ?? meta.label,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (diffs.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          HistoryDiffChips(diffs: diffs),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _openKeyTimeline(item.key),
                            icon: const Icon(Icons.timeline_rounded, size: 16),
                            label: const Text('키 전체 이력'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            PaginationBar(
              label: '변경 이력 총',
              totalCount: state.totalCount,
              currentPage: state.page,
              totalPages: state.totalPages,
              onPageSelected: notifier.goToPage,
            ),
          ],
        ],
      ),
    );
  }
}
