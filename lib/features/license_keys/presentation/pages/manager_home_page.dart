import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/sandbox/review_sandbox.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/license_service_type.dart';
import '../providers/license_key_provider.dart';
import '../providers/sales_stats_provider.dart';
import '../widgets/sales_stats_view.dart';
import 'license_management_view.dart';

/// 로그인 후 진입하는 여주자전거여행 시디키·간편서명키 통합 관리 메인 쉘 화면이다.
class ManagerHomePage extends ConsumerStatefulWidget {
  /// [ManagerHomePage] 위젯을 생성한다.
  const ManagerHomePage({super.key});

  @override
  ConsumerState<ManagerHomePage> createState() => _ManagerHomePageState();
}

class _ManagerHomePageState extends ConsumerState<ManagerHomePage> {
  int _selectedIndex = 0;

  LicenseServiceType? get _activeLicenseService {
    if (_selectedIndex == 0) return LicenseServiceType.miniPos;
    if (_selectedIndex == 1) return LicenseServiceType.sign;
    return null;
  }

  Future<void> _handleRefresh() async {
    final service = _activeLicenseService;
    if (service != null) {
      await ref.read(licenseKeyProvider(service).notifier).refreshAll();
    } else {
      await ref.read(salesStatsProvider.notifier).loadStatistics();
    }
  }

  Future<void> _handleExpireBatch() async {
    final service = _activeLicenseService;
    if (service == null) return;

    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: '만료 배치 점검 실행',
      message:
          '${service.displayLabel}의 기간이 지난 키를 즉시 사용 중지 상태로 전환하시겠습니까?',
      confirmLabel: '점검 실행',
      confirmColor: AppColors.primary,
    );
    if (!confirmed || !mounted) return;

    try {
      final modified = await ref
          .read(licenseKeyProvider(service).notifier)
          .runExpireBatch();
      if (!mounted) return;
      if (modified > 0) {
        AppFeedback.showSuccess(
          context,
          '만료 배치 점검 완료: $modified개의 기간 만료 키가 사용 중지되었습니다.',
        );
      } else {
        AppFeedback.showInfo(context, '현재 기간이 만료되어 추가 중지할 키가 없습니다.');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          extractErrorMessage(error, fallback: '만료 배치 실행에 실패했습니다.'),
        );
      }
    }
  }

  Future<void> _openAccountSheet() async {
    final authState = ref.read(authProvider);
    final config = ref.read(appConfigProvider);
    final isSandbox = ref.read(reviewSandboxProvider);
    final user = authState.user;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            user?.email ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (user != null && user.roles.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: user.roles
                        .map(
                          (role) => Chip(
                            label: Text(
                              role,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceSubtle,
                            side: const BorderSide(color: AppColors.border),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '실행 환경',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSandbox
                            ? '심사 테스트 샌드박스 (로컬 격리 데이터)'
                            : config.environment.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggingOut = ref.watch(authProvider.select((s) => s.isSubmitting));
    final activeService = _activeLicenseService;
    final isBatchRunning = activeService != null &&
        ref.watch(licenseKeyProvider(activeService)).isBatchRunning;

    final title = switch (_selectedIndex) {
      0 => 'MiniPos 시디키 관리',
      1 => '간편서명 키 관리',
      _ => '판매 통계',
    };

    return PopScope(
      canPop: !isLoggingOut,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Icon(
                    Icons.pedal_bike_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              actions: [
                if (activeService != null)
                  IconButton(
                    tooltip: '만료 배치 점검',
                    onPressed:
                        isLoggingOut || isBatchRunning ? null : _handleExpireBatch,
                    icon: isBatchRunning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shield_outlined),
                  ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: isLoggingOut ? null : _handleRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: '계정 정보 및 로그아웃',
                  onPressed: isLoggingOut ? null : _openAccountSheet,
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: const [
                LicenseManagementView(
                  key: ValueKey(LicenseServiceType.miniPos),
                  serviceType: LicenseServiceType.miniPos,
                ),
                LicenseManagementView(
                  key: ValueKey(LicenseServiceType.sign),
                  serviceType: LicenseServiceType.sign,
                ),
                SalesStatsView(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
                if (!ref.read(reviewSandboxProvider)) {
                  final screenName = switch (index) {
                    0 => 'minipos_manage',
                    1 => 'sign_manage',
                    _ => 'sales_statistics',
                  };
                  unawaited(
                    ref.read(appAnalyticsProvider).logScreenView(
                          screenName: screenName,
                        ),
                  );
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.vpn_key_outlined),
                  selectedIcon: Icon(Icons.vpn_key_rounded),
                  label: 'MiniPos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.draw_outlined),
                  selectedIcon: Icon(Icons.draw_rounded),
                  label: '간편서명',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: '판매통계',
                ),
              ],
            ),
          ),
          if (isLoggingOut)
            const Positioned.fill(
              child: _LogoutLoadingOverlay(),
            ),
        ],
      ),
    );
  }
}

/// 로그아웃 처리 중 사용자 조작을 차단하고 진행 상태를 표시하는 전체 화면 오버레이이다.
class _LogoutLoadingOverlay extends StatelessWidget {
  const _LogoutLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        Center(
          child: Card(
            elevation: 6,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.8),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '로그아웃 중...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
