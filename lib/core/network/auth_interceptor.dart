import 'dart:async';

import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
      {required SecureTokenStorage tokenStorage, required Dio refreshDio})
      : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio;

  final SecureTokenStorage _tokenStorage;
  final Dio _refreshDio;
  Completer<void>? _refreshCompleter;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final canRefresh =
        err.response?.statusCode == 401 && request.extra['retried'] != true;
    if (!canRefresh) {
      handler.next(err);
      return;
    }

    try {
      await _refreshAccessToken();
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthRefreshException('Unable to refresh session.');
      }

      request.extra['retried'] = true;
      request.headers['Authorization'] = 'Bearer $accessToken';
      final response = await _refreshDio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (error) {
      await _tokenStorage.clear();
      handler.next(err);
    }
  }

  Future<void> _refreshAccessToken() async {
    final activeRefresh = _refreshCompleter;
    if (activeRefresh != null) {
      await activeRefresh.future;
      return;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const AuthRefreshException('No refresh token is available.');
      }
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = response.data ?? const <String, dynamic>{};
      final access = data['access']?.toString();
      final refresh = data['refresh']?.toString() ?? refreshToken;
      if (access == null || access.isEmpty) {
        throw const AuthRefreshException(
            'Refresh response did not include an access token.');
      }
      await _tokenStorage
          .saveTokens(TokenPair(accessToken: access, refreshToken: refresh));
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
