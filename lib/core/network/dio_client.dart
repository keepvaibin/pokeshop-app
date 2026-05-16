import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient({required SecureTokenStorage tokenStorage}) {
    final baseOptions = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      headers: const {'Accept': 'application/json'},
    );

    refreshDio = Dio(baseOptions);
    dio = Dio(baseOptions)
      ..interceptors.add(
          AuthInterceptor(tokenStorage: tokenStorage, refreshDio: refreshDio));
  }

  late final Dio dio;
  late final Dio refreshDio;
}
