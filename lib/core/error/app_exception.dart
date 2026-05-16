import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  factory AppException.fromDio(DioException error) {
    if (error.response == null) {
      return AppException(_networkMessage(error), details: error.message);
    }

    final data = error.response?.data;
    final message =
        _safeMessage(_messageFromData(data), error.response?.statusCode);
    return AppException(
      message,
      statusCode: error.response?.statusCode,
      details: data,
    );
  }

  static String? _messageFromData(Object? data) {
    if (data is String && data.trim().isNotEmpty) return data;
    if (data is Map) {
      final detail = data['detail'] ?? data['error'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) return detail.join(', ');
      final values = data.values
          .map((value) => '$value')
          .where((value) => value.trim().isNotEmpty)
          .toList();
      if (values.isNotEmpty) return values.join('; ');
    }
    return null;
  }

  static String _safeMessage(String? rawMessage, int? statusCode) {
    final message = rawMessage?.trim() ?? '';
    if (message.isEmpty || _looksPrivateOrTechnical(message)) {
      return _fallbackForStatus(statusCode);
    }
    if ({
      'daily_limit_exceeded',
      'weekly_limit_exceeded',
      'total_limit_exceeded'
    }.contains(message)) {
      return 'There is a limit for this item.';
    }
    return message;
  }

  static bool _looksPrivateOrTechnical(String message) {
    final lower = message.toLowerCase();
    return lower.contains('<html') ||
        lower.contains('<div') ||
        lower.contains('application error') ||
        lower.contains('azurewebsites.net') ||
        lower.contains('scm.') ||
        lower.contains('api_base_url') ||
        lower.contains('traceback') ||
        lower.contains('stack trace') ||
        lower.contains('exception') ||
        lower.contains('django') ||
        lower.length > 220;
  }

  static String _fallbackForStatus(int? statusCode) {
    if (statusCode != null && statusCode >= 500) {
      return 'The shop is having trouble right now. Pull down to try again.';
    }
    return switch (statusCode) {
      400 => 'Please check the form and try again.',
      401 => 'Please sign in again.',
      403 => 'You do not have access to that.',
      404 => 'That item is not available anymore.',
      409 => 'Something changed. Pull down to refresh and try again.',
      429 => 'Please wait a moment and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  static String _networkMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        'Could not reach the shop. Check your connection and pull down to try again.',
      DioExceptionType.badCertificate =>
        'Could not connect securely. Please try again in a moment.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}

class AuthRefreshException extends AppException {
  const AuthRefreshException(super.message);
}
