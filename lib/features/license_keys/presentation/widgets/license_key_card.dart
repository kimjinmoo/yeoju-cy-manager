import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/license_key_models.dart';

/// 시디키 단건의 상태·메타데이터·관리 액션을 표시하는 카드 위젯이다.
class LicenseKeyCard extends StatelessWidget {
  /// [LicenseKeyCard] 위젯을 생성한다.
  const LicenseKeyCard({
    super.key,
    required this.item,
    required this.onCopyKey,
    required this.onShareDelivery,
    required this.onEdit,
    required this.onViewHistory,
    required this.onInitDevice,
    required this.onToggleReject,
    required this.onDelete,
  });

  /// 표시할 시디키 항목
  final LicenseKeyItem item;

  /// 키 복사 콜백
  final VoidCallback onCopyKey;

  /// 전달 URL 복사/공유 콜백
  final VoidCallback onShareDelivery;

  /// 정보 수정 콜백
  final VoidCallback onEdit;

  /// 변경 이력 보기 콜백
  final VoidCallback onViewHistory;

  /// 기기 연결 해제 콜백
  final VoidCallback onInitDevice;

  /// 사용 중지/정상 재개 토글 콜백
  final VoidCallback onToggleReject;

  /// 키 삭제 콜백
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        item.salesLocation != null && item.salesLocation!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 키 칩 + 상태 배지
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onCopyKey,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                item.key,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                LicenseStatusBadge(item: item),
              ],
            ),
            const SizedBox(height: 10),
            // 키 구분 + 판매처
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ToneBadge(
                  icon: Icons.sell_outlined,
                  label: item.isTestKey ? '테스트키' : '판매키',
                  foreground:
                      item.isTestKey ? AppColors.purple : AppColors.primary,
                  background: (item.isTestKey
                          ? AppColors.purple
                          : AppColors.primary)
                      .withValues(alpha: 0.1),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: hasLocation
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      hasLocation ? item.salesLocation!.trim() : '판매처 미입력',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            hasLocation ? FontWeight.w600 : FontWeight.w400,
                        color: hasLocation
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 사용 기간 + 연결 기기
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPeriodSection()),
                const SizedBox(width: 10),
                Expanded(child: _buildDeviceSection()),
              ],
            ),
            if (item.memo != null && item.memo!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.memo!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),
            // 하단: 발급일 + 관리 액션 버튼
            Row(
              children: [
                Text(
                  '발급: ${DateFormatter.formatDateTime(item.createDate)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ActionChipButton(
                  icon: Icons.share_outlined,
                  label: '전달',
                  foreground: AppColors.warning,
                  background: const Color(0xFFFF9500).withValues(alpha: 0.08),
                  borderColor: const Color(0xFFFF9500).withValues(alpha: 0.35),
                  onTap: onShareDelivery,
                ),
                _ActionChipButton(
                  icon: Icons.edit_outlined,
                  label: '수정',
                  onTap: onEdit,
                ),
                _ActionChipButton(
                  icon: Icons.history_rounded,
                  label: '이력',
                  onTap: onViewHistory,
                ),
                if (item.hasDevice)
                  _ActionChipButton(
                    icon: Icons.phonelink_erase_outlined,
                    label: '해제',
                    onTap: onInitDevice,
                  ),
                _ActionChipButton(
                  icon: item.isStopped
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  label: item.isStopped ? '재개' : '중지',
                  foreground:
                      item.isStopped ? AppColors.success : AppColors.textPrimary,
                  background: item.isStopped
                      ? AppColors.success.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderColor: item.isStopped
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.border,
                  onTap: onToggleReject,
                ),
                _ActionChipButton(
                  icon: Icons.delete_outline,
                  label: '삭제',
                  foreground: AppColors.danger,
                  background: AppColors.danger.withValues(alpha: 0.06),
                  borderColor: AppColors.danger.withValues(alpha: 0.25),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection() {
    if (item.isPermanent) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _ToneBadge(
          label: '영구적 (0일)',
          foreground: AppColors.teal,
          background: AppColors.teal.withValues(alpha: 0.1),
        ),
      );
    }

    final days = item.validDays ?? 0;
    final dday = DateFormatter.remainingDays(item.expireDate);
    var fg = AppColors.textPrimary;
    var bg = AppColors.background;
    var ddayLabel = '';

    if (dday != null) {
      if (dday <= 0) {
        fg = AppColors.danger;
        bg = AppColors.danger.withValues(alpha: 0.12);
        ddayLabel = '만료됨';
      } else if (dday <= 7) {
        fg = AppColors.warning;
        bg = const Color(0xFFFF9500).withValues(alpha: 0.14);
        ddayLabel = 'D-$dday';
      } else {
        ddayLabel = 'D-$dday';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToneBadge(
          label: '$days일${ddayLabel.isNotEmpty ? ' · $ddayLabel' : ''}',
          foreground: fg,
          background: bg,
        ),
        if (item.expireDate != null && item.expireDate!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '만료: ${DateFormatter.formatDateOnly(item.expireDate)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smartphone_outlined,
              size: 13,
              color:
                  item.hasDevice ? AppColors.textPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                item.hasDevice ? item.device! : '미연결',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: item.hasDevice ? 'monospace' : null,
                  fontSize: 12,
                  color: item.hasDevice
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        if (item.activatedDate != null && item.activatedDate!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '인증: ${DateFormatter.formatDateTime(item.activatedDate)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

/// 시디키 상태(`사용중`, `사용 대기`, `사용 중지`, `기간 만료`)를 표시하는 배지 위젯이다.
class LicenseStatusBadge extends StatelessWidget {
  /// [LicenseStatusBadge] 위젯을 생성한다.
  const LicenseStatusBadge({super.key, required this.item});

  /// 대상 키 항목
  final LicenseKeyItem item;

  @override
  Widget build(BuildContext context) {
    final dday = !item.isPermanent
        ? DateFormatter.remainingDays(item.expireDate)
        : null;
    final expiredByDate = dday != null && dday <= 0;

    if (item.isStopped) {
      final isExpired = item.rejectReason == 'EXPIRED' || expiredByDate;
      return _ToneBadge(
        icon: isExpired ? Icons.schedule : Icons.cancel_outlined,
        label: isExpired ? '기간 만료' : '사용 중지',
        foreground: AppColors.danger,
        background: AppColors.danger.withValues(alpha: 0.1),
      );
    }

    if (item.hasDevice) {
      return _ToneBadge(
        icon: Icons.check_circle_outline,
        label: '사용중',
        foreground: AppColors.success,
        background: AppColors.success.withValues(alpha: 0.12),
      );
    }

    return _ToneBadge(
      icon: Icons.vpn_key_outlined,
      label: '사용 대기',
      foreground: AppColors.textSecondary,
      background: AppColors.textMuted.withValues(alpha: 0.12),
    );
  }
}

class _ToneBadge extends StatelessWidget {
  const _ToneBadge({
    this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData? icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foreground = AppColors.textSecondary,
    this.background = AppColors.surface,
    this.borderColor = AppColors.border,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color foreground;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.5, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
