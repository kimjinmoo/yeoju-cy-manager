import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 앱 전역 SnackBar 및 확인 다이얼로그 헬퍼이다.
abstract final class AppFeedback {
  /// 성공 안내 스낵바를 표시한다.
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  /// 일반 정보/안내 스낵바를 표시한다.
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.textPrimary,
      icon: Icons.info_outline,
    );
  }

  /// 경고 안내 스낵바를 표시한다.
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// 오류 안내 스낵바를 표시한다.
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.danger,
      icon: Icons.error_outline,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// 위험·중요 작업 전 사용자 확인 다이얼로그를 표시한다.
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? subMessage,
    String confirmLabel = '확인',
    Color confirmColor = AppColors.primary,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
              if (subMessage != null && subMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: confirmColor),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
