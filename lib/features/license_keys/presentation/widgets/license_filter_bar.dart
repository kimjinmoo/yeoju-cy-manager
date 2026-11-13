import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/license_key_models.dart';

/// 시디키 목록 검색·상태·구분·판매처·페이지 크기 필터 툴바 위젯이다.
class LicenseFilterBar extends StatefulWidget {
  /// [LicenseFilterBar] 위젯을 생성한다.
  const LicenseFilterBar({
    super.key,
    required this.searchKeyword,
    required this.statusFilter,
    required this.keyTypeFilter,
    required this.salesLocationFilter,
    required this.salesLocations,
    required this.pageSize,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onKeyTypeChanged,
    required this.onSalesLocationChanged,
    required this.onPageSizeChanged,
  });

  /// 현재 검색어
  final String searchKeyword;

  /// 선택된 상태 필터
  final LicenseKeyStatusFilter statusFilter;

  /// 선택된 키 구분 필터 (null이면 전체)
  final LicenseKeyType? keyTypeFilter;

  /// 선택된 판매처 필터
  final String salesLocationFilter;

  /// 선택 가능한 판매처 목록
  final List<String> salesLocations;

  /// 페이지당 표시 건수
  final int pageSize;

  /// 디바운스된 검색어 변경 콜백
  final ValueChanged<String> onSearchChanged;

  /// 상태 필터 변경 콜백
  final ValueChanged<LicenseKeyStatusFilter> onStatusChanged;

  /// 키 구분 필터 변경 콜백
  final ValueChanged<LicenseKeyType?> onKeyTypeChanged;

  /// 판매처 필터 변경 콜백
  final ValueChanged<String> onSalesLocationChanged;

  /// 페이지 크기 변경 콜백
  final ValueChanged<int> onPageSizeChanged;

  @override
  State<LicenseFilterBar> createState() => _LicenseFilterBarState();
}

class _LicenseFilterBarState extends State<LicenseFilterBar> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchKeyword);
  }

  @override
  void didUpdateWidget(covariant LicenseFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchKeyword != oldWidget.searchKeyword &&
        widget.searchKeyword != _searchController.text.trim()) {
      _searchController.text = widget.searchKeyword;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onSearchChanged(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색창
          TextField(
            controller: _searchController,
            onChanged: _onInputChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: '시디키, 판매처, 연결 기기 ID, 비고로 검색...',
              prefixIcon: const Icon(Icons.search, size: 19),
              isDense: true,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close, size: 17),
                      tooltip: '검색어 지우기',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          // 상태 필터 칩
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LicenseKeyStatusFilter.values.map((filter) {
                final selected = widget.statusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterPill(
                    label: filter.label,
                    selected: selected,
                    activeColor: AppColors.textPrimary,
                    onTap: () => widget.onStatusChanged(filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // 키 구분 + 판매처 + 페이지 크기
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterPill(
                label: '구분 전체',
                selected: widget.keyTypeFilter == null,
                activeColor: AppColors.textPrimary,
                onTap: () => widget.onKeyTypeChanged(null),
              ),
              _FilterPill(
                label: '판매키',
                selected: widget.keyTypeFilter == LicenseKeyType.sale,
                activeColor: AppColors.primary,
                onTap: () => widget.onKeyTypeChanged(LicenseKeyType.sale),
              ),
              _FilterPill(
                label: '테스트키',
                selected: widget.keyTypeFilter == LicenseKeyType.test,
                activeColor: AppColors.purple,
                onTap: () => widget.onKeyTypeChanged(LicenseKeyType.test),
              ),
              _CompactDropdown<String>(
                value: widget.salesLocationFilter,
                items: [
                  const DropdownMenuItem(value: '', child: Text('판매처 전체')),
                  ...widget.salesLocations.map(
                    (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
                  ),
                  const DropdownMenuItem(
                    value: emptySalesLocationToken,
                    child: Text('판매처 미입력'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) widget.onSalesLocationChanged(v);
                },
              ),
              _CompactDropdown<int>(
                value: widget.pageSize,
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10개씩')),
                  DropdownMenuItem(value: 20, child: Text('20개씩')),
                  DropdownMenuItem(value: 50, child: Text('50개씩')),
                ],
                onChanged: (v) {
                  if (v != null) widget.onPageSizeChanged(v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    // 현재 값이 목록에 없는 경우 안전하게 첫 번째 항목으로 보정한다.
    final hasValue = items.any((item) => item.value == value);
    final safeValue = hasValue ? value : items.first.value;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
