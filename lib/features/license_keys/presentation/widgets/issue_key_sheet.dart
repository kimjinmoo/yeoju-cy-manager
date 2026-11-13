import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_feedback.dart';
import '../../domain/license_key_models.dart';
import '../../domain/license_service_type.dart';
import '../providers/license_key_provider.dart';

/// 시디키 일괄 발급 및 결과 확인 모달 바텀시트 위젯이다.
class IssueKeySheet extends ConsumerStatefulWidget {
  /// [IssueKeySheet] 위젯을 생성한다.
  const IssueKeySheet({
    super.key,
    required this.serviceType,
    required this.knownSalesLocations,
  });

  /// 대상 서비스 타입
  final LicenseServiceType serviceType;

  /// 추천 판매처 목록
  final List<String> knownSalesLocations;

  @override
  ConsumerState<IssueKeySheet> createState() => _IssueKeySheetState();
}

class _IssueKeySheetState extends ConsumerState<IssueKeySheet> {
  final _salesLocationController = TextEditingController();
  final _validDaysController = TextEditingController(text: '30');
  final _countController = TextEditingController(text: '1');
  final _memoController = TextEditingController();

  LicenseKeyType _keyType = LicenseKeyType.sale;
  bool _isPermanent = true;
  bool _isSubmitting = false;
  List<LicenseKeyItem>? _issuedResult;

  @override
  void dispose() {
    _salesLocationController.dispose();
    _validDaysController.dispose();
    _countController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _selectKeyType(LicenseKeyType nextType) {
    setState(() {
      _keyType = nextType;
      if (nextType == LicenseKeyType.test && _isPermanent) {
        _isPermanent = false;
        _validDaysController.text = '7';
      }
    });
  }

  Future<void> _submit() async {
    final validDays = _isPermanent
        ? 0
        : (int.tryParse(_validDaysController.text.trim()) ?? 0);
    if (!_isPermanent && validDays < 1) {
      AppFeedback.showWarning(context, '기간제 키는 1일 이상으로 입력해주세요.');
      return;
    }

    final rawCount = int.tryParse(_countController.text.trim()) ?? 1;
    final count = rawCount.clamp(1, 100);

    setState(() => _isSubmitting = true);
    try {
      final created =
          await ref.read(licenseKeyProvider(widget.serviceType).notifier).issueKeys(
                LicenseKeyCreatePayload(
                  count: count,
                  keyType: _keyType,
                  salesLocation: _salesLocationController.text.trim(),
                  validDays: validDays,
                  memo: _memoController.text.trim(),
                ),
              );

      if (created.isNotEmpty) {
        await Clipboard.setData(
          ClipboardData(text: created.map((e) => e.key).join('\n')),
        );
      }

      if (!mounted) return;
      setState(() {
        _issuedResult = created;
        _isSubmitting = false;
      });
      AppFeedback.showSuccess(
        context,
        '${created.length}개의 시디키가 발급 및 클립보드에 복사되었습니다.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppFeedback.showError(
        context,
        extractErrorMessage(error, fallback: '시디키 발급에 실패했습니다.'),
      );
    }
  }

  String _previewExpireText() {
    if (_isPermanent) return '만료 없이 영구적으로 사용 가능합니다.';
    final days = (int.tryParse(_validDaysController.text.trim()) ?? 1).clamp(1, 3650);
    final previewDate = DateTime.now().add(Duration(days: days));
    return '발급 시점부터 $days일간 유효 · 만료 예정: ${DateFormatter.formatKoreanDate(previewDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final webHost = ref.watch(appConfigProvider).webHost;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  Expanded(
                    child: Text(
                      _issuedResult != null
                          ? '시디키 발급 완료'
                          : '${widget.serviceType.displayLabel} 시디키 발급',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_issuedResult != null)
                _buildResultView(_issuedResult!, webHost)
              else
                _buildFormView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final selectedLocation = _salesLocationController.text.trim();
    final currentDays = int.tryParse(_validDaysController.text.trim()) ?? 0;
    final currentCount = int.tryParse(_countController.text.trim()) ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('키 구분'),
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
          onSelectionChanged: (set) => _selectKeyType(set.first),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('판매처 / 발급처'),
        TextField(
          controller: _salesLocationController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: '예: 여주 본점, 스마트스토어'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.knownSalesLocations.map((loc) {
            final selected = selectedLocation == loc;
            return ChoiceChip(
              label: Text(loc, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) {
                setState(() => _salesLocationController.text = loc);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('사용 기간 (유효 기간)'),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('영구적 (0일 · 무제한)')),
            ButtonSegment(value: false, label: Text('기간 제한 (day 단위)')),
          ],
          selected: {_isPermanent},
          onSelectionChanged: (set) => setState(() => _isPermanent = set.first),
        ),
        if (!_isPermanent) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _validDaysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(suffixText: '일'),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '일 (1~3650)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
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
                  setState(() => _validDaysController.text = '$days');
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: (_isPermanent ? AppColors.teal : AppColors.primary)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _previewExpireText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isPermanent ? AppColors.teal : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('발급 수량 (1~100개)'),
        Row(
          children: [
            SizedBox(
              width: 110,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(suffixText: '개'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [1, 5, 10, 20].map((c) {
                  return ChoiceChip(
                    label: Text('$c개', style: const TextStyle(fontSize: 12)),
                    selected: currentCount == c,
                    onSelected: (_) {
                      setState(() => _countController.text = '$c');
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionLabel('비고 (선택)'),
        TextField(
          controller: _memoController,
          decoration: const InputDecoration(
            hintText: '구매자명, 연락처, 계약 메모 등을 입력하세요',
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? '발급 중...' : '시디키 발급하기'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView(List<LicenseKeyItem> created, String webHost) {
    final locationLabel = _salesLocationController.text.trim().isEmpty
        ? '미입력'
        : _salesLocationController.text.trim();
    final periodLabel = _isPermanent
        ? '영구적(0일)'
        : '${int.tryParse(_validDaysController.text.trim()) ?? 0}일';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${created.length}개의 시디키가 즉시 발급 및 저장되었습니다.',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '구분: ${_keyType.label} · 판매처: $locationLabel · 기간: $periodLabel',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: created.map((e) => e.key).join('\n')),
                  );
                  if (mounted) {
                    AppFeedback.showSuccess(context, '발급된 전체 키가 복사되었습니다.');
                  }
                },
                icon: const Icon(Icons.copy_all, size: 16),
                label: const Text('전체 키 복사'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: created.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = created[index];
              final deliveryUrl = widget.serviceType.buildDeliveryUrl(
                webHost: webHost,
                key: item.key,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '키 복사',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.key));
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            '${item.key} 복사 완료',
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                    ),
                    IconButton(
                      tooltip: '전달 URL 공유',
                      onPressed: () async {
                        await SharePlus.instance.share(
                          ShareParams(
                            text: deliveryUrl,
                            subject: '${widget.serviceType.shortLabel} 시디키 전달',
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('완료'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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
