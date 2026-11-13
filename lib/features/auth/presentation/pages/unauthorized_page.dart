import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// 로그인은 완료되었으나 `ADMIN` 또는 `YEOJU_CYCLE_ADMIN` 권한이 없는 사용자에게 표시하는 안내 화면이다.
class UnauthorizedPage extends ConsumerWidget {
  /// [UnauthorizedPage] 위젯을 생성한다.
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 32,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '관리자 접근 권한이 필요합니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '현재 로그인된 계정(${user?.email ?? '-'})에는 여주자전거여행 시디키·간편서명 관리 권한(ADMIN 또는 YEOJU_CYCLE_ADMIN)이 없습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (user != null && user.roles.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: user.roles
                              .map(
                                (r) => Chip(
                                  label: Text(
                                    r,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: AppColors.surfaceSubtle,
                                  side: const BorderSide(color: AppColors.border),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: authState.isSubmitting
                              ? null
                              : () => ref.read(authProvider.notifier).logout(),
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('다른 계정으로 로그인'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
