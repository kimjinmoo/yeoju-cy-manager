import 'package:flutter/material.dart';

/// 앱 전반에서 사용하는 컬러 팔레트 및 Material 3 테마 정의이다.
///
/// `console_grepiu`의 Apple 스타일 라이트 톤(`#0071E3` 포인트, `#F5F5F7` 배경)을 기반으로 한다.
abstract final class AppColors {
  /// 메인 브랜드 블루 (`#0071E3`)
  static const primary = Color(0xFF0071E3);

  /// 호버/강조 블루 (`#005BB5`)
  static const primaryDark = Color(0xFF005BB5);

  /// 앱 배경 그레이 (`#F5F5F7`)
  static const background = Color(0xFFF5F5F7);

  /// 카드 서피스 화이트
  static const surface = Color(0xFFFFFFFF);

  /// 보조 서피스 (`#F8F8FA`)
  static const surfaceSubtle = Color(0xFFF8F8FA);

  /// 기본 본문 텍스트 (`#1D1D1F`)
  static const textPrimary = Color(0xFF1D1D1F);

  /// 보조 본문 텍스트 (`#515154`)
  static const textSecondary = Color(0xFF515154);

  /// 캡션/힌트 텍스트 (`#86868B`)
  static const textMuted = Color(0xFF86868B);

  /// 보더 컬러 (`#E5E5EA`)
  static const border = Color(0xFFE5E5EA);

  /// 연한 보더 (`#ECECEF`)
  static const borderSubtle = Color(0xFFECECEF);

  /// 성공/사용중 그린 (`#1F8B3D`)
  static const success = Color(0xFF1F8B3D);

  /// 경고/만료임박 오렌지 (`#B25E00`)
  static const warning = Color(0xFFB25E00);

  /// 주의 배경 (`#FFFAF0`)
  static const warningBg = Color(0xFFFFFAF0);

  /// 오류/중지 레드 (`#D70015`)
  static const danger = Color(0xFFD70015);

  /// 테스트키 퍼플 (`#6D28D9`)
  static const purple = Color(0xFF6D28D9);

  /// 영구키 틸 (`#0F766E`)
  static const teal = Color(0xFF0F766E);
}

/// 앱 전역 라이트 테마를 반환한다.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
