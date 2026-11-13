import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/license_key_repository.dart';
import '../../domain/license_key_models.dart';
import '../../domain/license_service_type.dart';
import '../utils/history_diff_helper.dart';

/// 개별 시디키의 변경 이력 타임라인을 보여주는 바텀시트 위젯이다.
class KeyHistorySheet extends ConsumerStatefulWidget {
  /// [KeyHistorySheet] 위젯을 생성한다.
  const KeyHistorySheet({
    super.key,
    required this.serviceType,
    required this.targetKey,
  });

  /// 대상 서비스
  final LicenseServiceType serviceType;

  /// 조회할 시디키
  final String targetKey;

  @override
  ConsumerState<KeyHistorySheet> createState() => _KeyHistorySheetState();
}

class _KeyHistorySheetState extends ConsumerState<KeyHistorySheet> {
  bool _isLoading = true;
  String? _error;
  List<LicenseKeyHistoryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ref.read(licenseKeyRepositoryProvider).fetchHistories(
            serviceType: widget.serviceType,
            key: widget.targetKey,
            page: 0,
            size: 50,
          );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = extractErrorMessage(
          error,
          fallback: '해당 키의 변경 이력을 불러오지 못했습니다.',
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '시디키 변경 이력',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.targetKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _buildBody(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          title: '이력을 불러오지 못했습니다',
          description: _error!,
          actionLabel: '다시 시도',
          onAction: _load,
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.history_toggle_off,
          title: '기록된 변경 이력이 없습니다',
          description: '발급·수정·인증·중지·만료 변경 사항이 발생하면 이곳에 타임라인으로 기록됩니다.',
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final meta = HistoryDiffHelper.resolveActionMeta(item.actionType);
        final diffs = HistoryDiffHelper.buildDiffs(
          item.beforeData,
          item.afterData,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HistoryActionBadge(meta: meta),
                  const SizedBox(width: 8),
                  Icon(
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
            ],
          ),
        );
      },
    );
  }
}

/// 변경 이력 액션 배지 위젯이다.
class HistoryActionBadge extends StatelessWidget {
  /// [HistoryActionBadge] 위젯을 생성한다.
  const HistoryActionBadge({super.key, required this.meta});

  /// 액션 메타데이터
  final HistoryActionMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: meta.foreground,
        ),
      ),
    );
  }
}

/// 변경 전·후 필드 비교 칩 목록 위젯이다.
class HistoryDiffChips extends StatelessWidget {
  /// [HistoryDiffChips] 위젯을 생성한다.
  const HistoryDiffChips({super.key, required this.diffs});

  /// 비교 항목 목록
  final List<SnapshotDiffEntry> diffs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: diffs.map((d) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              if (d.before != null) ...[
                Text(
                  d.before!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              Flexible(
                child: Text(
                  d.after,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
