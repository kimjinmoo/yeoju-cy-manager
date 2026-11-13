import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/pagination_bar.dart';
import '../../domain/license_key_models.dart';
import '../../domain/license_service_type.dart';
import '../providers/license_key_provider.dart';
import '../widgets/edit_key_sheet.dart';
import '../widgets/history_list_view.dart';
import '../widgets/issue_key_sheet.dart';
import '../widgets/key_history_sheet.dart';
import '../widgets/kpi_summary_strip.dart';
import '../widgets/license_filter_bar.dart';
import '../widgets/license_key_card.dart';

enum _ManagementSubTab { keys, history }

/// 특정 서비스([LicenseServiceType.miniPos] 또는 [LicenseServiceType.sign])의 시디키 목록과 변경 이력을 관리하는 화면이다.
class LicenseManagementView extends ConsumerStatefulWidget {
  /// [LicenseManagementView] 위젯을 생성한다.
  const LicenseManagementView({super.key, required this.serviceType});

  /// 관리할 서비스 타입
  final LicenseServiceType serviceType;

  @override
  ConsumerState<LicenseManagementView> createState() =>
      _LicenseManagementViewState();
}

class _LicenseManagementViewState extends ConsumerState<LicenseManagementView> {
  _ManagementSubTab _subTab = _ManagementSubTab.keys;
  static final _numFmt = NumberFormat.decimalPattern('ko_KR');

  void _openIssueSheet(List<String> knownSalesLocations) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => IssueKeySheet(
        serviceType: widget.serviceType,
        knownSalesLocations: knownSalesLocations,
      ),
    );
  }

  void _openEditSheet(
    LicenseKeyItem item,
    List<String> knownSalesLocations,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditKeySheet(
        serviceType: widget.serviceType,
        item: item,
        knownSalesLocations: knownSalesLocations,
        onOpenHistory: () => _openKeyHistorySheet(item.key),
      ),
    );
  }

  void _openKeyHistorySheet(String key) {
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

  Future<void> _copyText(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppFeedback.showSuccess(context, successMessage);
    }
  }

  Future<void> _shareDelivery(LicenseKeyItem item) async {
    final webHost = ref.read(appConfigProvider).webHost;
    final url = widget.serviceType.buildDeliveryUrl(
      webHost: webHost,
      key: item.key,
    );
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      AppFeedback.showSuccess(context, '전달 URL이 복사되었습니다. 모바일로 공유하세요!');
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: url,
          subject: '${widget.serviceType.shortLabel} 시디키 전달 (${item.key})',
        ),
      );
    } catch (_) {
      // 클립보드 복사는 이미 완료되었으므로 공유 시트 미지원 환경 오류는 무시한다.
    }
  }

  Future<void> _confirmToggleReject(LicenseKeyItem item) async {
    final notifier =
        ref.read(licenseKeyProvider(widget.serviceType).notifier);
    if (item.isStopped) {
      try {
        await notifier.toggleReject(item);
        if (mounted) {
          AppFeedback.showSuccess(context, '${item.key} 키가 정상 재개 처리되었습니다.');
        }
      } catch (error) {
        if (mounted) {
          AppFeedback.showError(
            context,
            extractErrorMessage(error, fallback: '정상 재개 처리에 실패했습니다.'),
          );
        }
      }
      return;
    }

    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: '시디키 사용 중지 확인',
      message: '대상 키: ${item.key}\n사용 중지 처리 시 해당 키는 즉시 인증 거부 상태가 됩니다.',
      subMessage: '필요 시 언제든 재개 버튼으로 다시 정상 상태로 복구할 수 있습니다.',
      confirmLabel: '사용 중지 실행',
      confirmColor: AppColors.danger,
    );
    if (!confirmed) return;

    try {
      await notifier.toggleReject(item);
      if (mounted) {
        AppFeedback.showSuccess(context, '${item.key} 키가 사용 중지 처리되었습니다.');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          extractErrorMessage(error, fallback: '사용 중지 처리에 실패했습니다.'),
        );
      }
    }
  }

  Future<void> _confirmInitDevice(LicenseKeyItem item) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: '기기 연결 해제(초기화)',
      message:
          '대상 키: ${item.key}\n현재 연결된 단말기(${item.device ?? '-'})가 해제되어 새 기기에서 다시 인증할 수 있게 됩니다.',
      subMessage: '판매처, 키 구분, 남은 유효 기간 정보는 그대로 유지됩니다.',
      confirmLabel: '기기 연결 해제',
      confirmColor: const Color(0xFFFF9500),
    );
    if (!confirmed) return;

    try {
      await ref
          .read(licenseKeyProvider(widget.serviceType).notifier)
          .initDevice(item.key);
      if (mounted) {
        AppFeedback.showSuccess(context, '${item.key} 기기 연결이 초기화되었습니다.');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          extractErrorMessage(error, fallback: '기기 초기화에 실패했습니다.'),
        );
      }
    }
  }

  Future<void> _confirmDeleteKey(LicenseKeyItem item) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: '시디키 삭제 확인',
      message: '대상 키: ${item.key}',
      subMessage: '삭제한 시디키는 복구할 수 없으며 단말기 인증이 즉시 실패합니다. 삭제하시겠습니까?',
      confirmLabel: '삭제하기',
      confirmColor: AppColors.danger,
    );
    if (!confirmed) return;

    try {
      await ref
          .read(licenseKeyProvider(widget.serviceType).notifier)
          .deleteKey(item.key);
      if (mounted) {
        AppFeedback.showSuccess(context, '${item.key} 키가 삭제되었습니다.');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          extractErrorMessage(error, fallback: '키 삭제에 실패했습니다.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(licenseKeyProvider(widget.serviceType));
    final notifier =
        ref.read(licenseKeyProvider(widget.serviceType).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _subTab == _ManagementSubTab.keys
          ? FloatingActionButton.extended(
              heroTag: 'issue_fab_${widget.serviceType.name}',
              onPressed: () => _openIssueSheet(state.knownSalesLocations),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                '시디키 발급',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Column(
        children: [
          // 서브 탭 (시디키 목록 / 변경 이력)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<_ManagementSubTab>(
                        segments: [
                          ButtonSegment(
                            value: _ManagementSubTab.keys,
                            icon: const Icon(Icons.list_alt_rounded, size: 17),
                            label: Text(
                              '시디키 목록 (${_numFmt.format(state.summary.total)})',
                            ),
                          ),
                          const ButtonSegment(
                            value: _ManagementSubTab.history,
                            icon: Icon(Icons.timeline_rounded, size: 17),
                            label: Text('변경 이력'),
                          ),
                        ],
                        selected: {_subTab},
                        onSelectionChanged: (set) {
                          setState(() => _subTab = set.first);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _subTab == _ManagementSubTab.keys
                ? RefreshIndicator(
                    onRefresh: notifier.refreshAll,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
                      children: [
                        KpiSummaryStrip(
                          summary: state.summary,
                          activeFilter: state.statusFilter,
                          onSelectFilter: notifier.setStatusFilter,
                        ),
                        const SizedBox(height: 12),
                        LicenseFilterBar(
                          searchKeyword: state.searchKeyword,
                          statusFilter: state.statusFilter,
                          keyTypeFilter: state.keyTypeFilter,
                          salesLocationFilter: state.salesLocationFilter,
                          salesLocations: state.filterSalesLocations,
                          pageSize: state.pageSize,
                          onSearchChanged: notifier.setSearchKeyword,
                          onStatusChanged: notifier.setStatusFilter,
                          onKeyTypeChanged: notifier.setKeyTypeFilter,
                          onSalesLocationChanged:
                              notifier.setSalesLocationFilter,
                          onPageSizeChanged: notifier.setPageSize,
                        ),
                        const SizedBox(height: 12),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.errorMessage != null)
                          EmptyStateView(
                            icon: Icons.cloud_off_rounded,
                            title: '시디키 목록을 불러오지 못했습니다',
                            description: state.errorMessage!,
                            actionLabel: '다시 시도',
                            onAction: notifier.refreshAll,
                          )
                        else if (state.items.isEmpty)
                          EmptyStateView(
                            icon: Icons.vpn_key_outlined,
                            title: '조건에 맞는 시디키가 없습니다',
                            description: '검색어나 필터를 초기화하거나 새 시디키를 발급해보세요.',
                            actionLabel: '시디키 발급하기',
                            onAction: () =>
                                _openIssueSheet(state.knownSalesLocations),
                          )
                        else ...[
                          ...state.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LicenseKeyCard(
                                item: item,
                                onCopyKey: () =>
                                    _copyText(item.key, '${item.key} 복사 완료'),
                                onShareDelivery: () => _shareDelivery(item),
                                onEdit: () => _openEditSheet(
                                  item,
                                  state.knownSalesLocations,
                                ),
                                onViewHistory: () =>
                                    _openKeyHistorySheet(item.key),
                                onInitDevice: () => _confirmInitDevice(item),
                                onToggleReject: () =>
                                    _confirmToggleReject(item),
                                onDelete: () => _confirmDeleteKey(item),
                              ),
                            ),
                          ),
                          PaginationBar(
                            label: '검색 결과 총',
                            totalCount: state.totalCount,
                            currentPage: state.page,
                            totalPages: state.totalPages,
                            onPageSelected: notifier.goToPage,
                          ),
                        ],
                      ],
                    ),
                  )
                : HistoryListView(serviceType: widget.serviceType),
          ),
        ],
      ),
    );
  }
}
