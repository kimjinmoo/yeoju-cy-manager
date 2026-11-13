import 'package:intl/intl.dart';

/// 날짜·시간 및 잔여 유효 일수(D-Day) 포맷팅 유틸리티이다.
abstract final class DateFormatter {
  static final _dateTimeFmt = DateFormat('yy.MM.dd HH:mm');
  static final _dateOnlyFmt = DateFormat('yyyy.MM.dd');
  static final _koreanDateFmt = DateFormat('yyyy년 M월 d일');

  /// ISO 문자열을 `yy.MM.dd HH:mm` 형식으로 변환한다.
  static String formatDateTime(String? raw) {
    final dt = tryParse(raw);
    if (dt == null) return '-';
    return _dateTimeFmt.format(dt.toLocal());
  }

  /// ISO 문자열을 `yyyy.MM.dd` 형식으로 변환한다.
  static String formatDateOnly(String? raw) {
    final dt = tryParse(raw);
    if (dt == null) return '-';
    return _dateOnlyFmt.format(dt.toLocal());
  }

  /// [DateTime]을 한국어 날짜(`yyyy년 M월 d일`)로 변환한다.
  static String formatKoreanDate(DateTime dateTime) {
    return _koreanDateFmt.format(dateTime.toLocal());
  }

  /// 만료 일시 기준 잔여 일수를 계산한다. (음수/0 이하면 만료됨)
  static int? remainingDays(String? expireDateRaw, {DateTime? now}) {
    final end = tryParse(expireDateRaw);
    if (end == null) return null;
    final baseline = now ?? DateTime.now();
    final diffMs = end.millisecondsSinceEpoch - baseline.millisecondsSinceEpoch;
    return (diffMs / Duration.millisecondsPerDay).ceil();
  }

  /// 날짜 문자열을 안전하게 파싱한다.
  static DateTime? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
}
