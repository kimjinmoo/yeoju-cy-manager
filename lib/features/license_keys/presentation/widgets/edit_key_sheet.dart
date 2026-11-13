import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../domain/license_key_models.dart';
import '../../domain/license_service_type.dart';
import '../providers/license_key_provider.dart';
import 'license_key_card.dart';

/// 시디키 메타데이터(구분, 판매처, 유효기간, 복구, 비고)를 수정하는 모달 바텀시트 위젯이다.
class EditKeySheet extends ConsumerStatefulWidget {
  /// [EditKeySheet] 위젯을 생성한다.
  const EditKeySheet({
    super.key,
    required this.serviceType,
    required this.item,
    required this.knownSalesLocations,
    required this.onOpenHistory,
  });

  /// 대상 서비스
  final LicenseServiceType serviceType;

  /// 수정 대상 시디키
  final LicenseKeyItem item;

  /// 추천 판매처 목록
  final List<String> knownSalesLocations;

  /// 해당 키의 변경 이력 시트 열기 콜백
  final VoidCallback onOpenHistory;

  @override
  ConsumerState<EditKeySheet> createState() => _EditKeySheetState();
}

class _EditKeySheetState extends ConsumerState<EditKeySheet> {
  late final TextEditingController _salesLocationController;
  late final TextEditingController _validDaysController;
  late final TextEditingController _memoController;

  late LicenseKeyType _keyType;
  late bool _isPermanent;
  bool _recalculateExpire = false;
  late bool _reactivate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final days = item.validDays ?? 0;

    _keyType = LicenseKeyType.fromRaw(item.keyType);
    _isPermanent = days <= 0;
    _reactivate = item.isStopped;

    _salesLocationController = TextEditingController(
      text: item.salesLocation ?? '',
    );
    _validDaysController = TextEditingController(
      text: '${days > 0 ? days : 30}',
    );
    _memoController = TextEditingController(text: item.memo ?? '');
  }

  @override
  void dispose() {
    _salesLocationController.dispose();
    _validDaysController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validDays = _isPermanent
        ? 0
        : (int.tryParse(_validDaysController.text.trim()) ?? 0);
    if (!_isPermanent && validDays < 1) {
      AppFeedback.showWarning(context, '기간제 키는 1일 이상으로 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(licenseKeyProvider(widget.serviceType).notifier)
          .updateKeyInfo(
            LicenseKeyUpdatePayload(
              key: widget.item.key,
              keyType: _keyType,
              salesLocation: _salesLocationController.text.trim(),
              validDays: validDays,
              recalculateExpire: _recalculateExpire,
              reactivate: _reactivate,
              memo: _memoController.text,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, '${widget.item.key} 정보가 수정되었습니다.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppFeedback.showError(
        context,
        extractErrorMessage(error, fallback: '키 정보 수정에 실패했습니다.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedLocation = _salesLocationController.text.trim();
    final currentDays = int.tryParse(_validDaysController.text.trim()) ?? 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '시디키 정보 수정',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.key,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    LicenseStatusBadge(item: widget.item),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('키 구분'),
              SegmentedButton<LicenseKeyType>(
                segments: const [
                  ButtonSegment(
                    value: LicenseKeyType.sale,
                    label: Text('판매키 (SALE)'),
                  ),
                  ButtonSegment(
                    value: LicenseKeyType.test,
                    label: Text('테스트키 (TEST)'),
                  ),
                ],
                selected: {_keyType},
                onSelectionChanged: (set) =>
                    setState(() => _keyType = set.first),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('판매처 / 발급처'),
              TextField(
                controller: _salesLocationController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: '판매처 입력'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.knownSalesLocations.map((loc) {
                  return ChoiceChip(
                    label: Text(loc, style: const TextStyle(fontSize: 12)),
                    selected: selectedLocation == loc,
                    onSelected: (_) {
                      setState(() => _salesLocationController.text = loc);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('사용 기간'),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('영구적 (0일)')),
                  ButtonSegment(value: false, label: Text('기간 제한 (day)')),
                ],
                selected: {_isPermanent},
                onSelectionChanged: (set) =>
                    setState(() => _isPermanent = set.first),
              ),
              if (!_isPermanent) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _validDaysController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(suffixText: '일'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (widget.item.expireDate != null &&
                        widget.item.expireDate!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '현재 만료일: ${DateFormatter.formatDateOnly(widget.item.expireDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: licensePeriodPresets.map((days) {
                    return ChoiceChip(
                      label: Text('$days일', style: const TextStyle(fontSize: 12)),
                      selected: currentDays == days,
                      onSelected: (_) {
                        setState(() {
                          _validDaysController.text = '$days';
                          _recalculateExpire = true;
                        });
                      },
                    );
                  }).toList(),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _recalculateExpire,
                  onChanged: (v) =>
                      setState(() => _recalculateExpire = v ?? false),
                  title: const Text(
                    '오늘 시점부터 만료일 다시 계산하기',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              if (widget.item.isStopped)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reactivate,
                  onChanged: (v) => setState(() => _reactivate = v ?? false),
                  title: const Text(
                    '사용 중지(만료/거부) 해제하고 정상 상태로 복구하기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const SizedBox(height: 8),
              const _FieldLabel('비고'),
              TextField(
                controller: _memoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '참고할 내용을 입력하세요...',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onOpenHistory();
                          },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('이력'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? '저장 중...' : '저장하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
