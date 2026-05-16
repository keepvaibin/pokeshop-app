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
        _messageFromData(data) ?? error.message ?? 'Something went wrong.';
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

  static String _networkMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        'Could not reach the SCTCG API. Check your connection or API_BASE_URL.',
      DioExceptionType.badCertificate =>
        'The SCTCG API certificate could not be trusted.',
      _ => error.message ?? 'Something went wrong.',
    };
  }

  @override
  String toString() => message;
}

class AuthRefreshException extends AppException {
  const AuthRefreshException(super.message);
}
