import 'package:dio/dio.dart';

/// 백엔드 API 호출 중 발생한 오류를 일관되게 표현하는 예외 클래스이다.
class ApiException implements Exception {
  /// [ApiException] 인스턴스를 생성한다.
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  /// [DioException]으로부터 사용자 친화적인 한글 오류 메시지를 추출한다.
  factory ApiException.fromDio(
    DioException error, {
    String fallback = '요청 처리 중 오류가 발생했습니다.',
  }) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? serverMessage;
    String? serverCode;

    if (data is Map<String, dynamic>) {
      final rawMsg = data['message'];
      final rawCode = data['code'];
      if (rawMsg is String && rawMsg.trim().isNotEmpty) {
        serverMessage = rawMsg.trim();
      }
      if (rawCode is String && rawCode.trim().isNotEmpty) {
        serverCode = rawCode.trim();
      }
    }

    if (serverMessage != null) {
      return ApiException(
        message: serverMessage,
        statusCode: statusCode,
        code: serverCode,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: '서버 응답 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.',
          statusCode: statusCode,
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: '서버에 연결할 수 없습니다. 서버 주소와 네트워크를 확인해주세요.',
          statusCode: statusCode,
          code: 'CONNECTION_ERROR',
        );
      default:
        if (statusCode == 401) {
          return const ApiException(
            message: '인증이 만료되었거나 유효하지 않습니다. 다시 로그인해주세요.',
            statusCode: 401,
            code: 'UNAUTHORIZED',
          );
        }
        if (statusCode == 403) {
          return const ApiException(
            message: '해당 기능에 대한 접근 권한이 없습니다.',
            statusCode: 403,
            code: 'FORBIDDEN',
          );
        }
        return ApiException(
          message: serverCode ?? fallback,
          statusCode: statusCode,
          code: serverCode,
        );
    }
  }

  /// 화면에 표시할 오류 메시지
  final String message;

  /// HTTP 상태 코드
  final int? statusCode;

  /// 서버 StandardResponse 오류 코드
  final String? code;

  @override
  String toString() => message;
}

/// 임의의 예외 객체에서 표시용 오류 메시지를 안전하게 추출한다.
String extractErrorMessage(
  Object error, {
  String fallback = '요청 처리에 실패했습니다.',
}) {
  if (error is ApiException) return error.message;
  if (error is DioException) return ApiException.fromDio(error, fallback: fallback).message;
  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length);
  }
  return raw.isNotEmpty ? raw : fallback;
}
