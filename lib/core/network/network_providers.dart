import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'dio_client.dart';

final secureTokenStorageProvider =
    Provider<SecureTokenStorage>((ref) => SecureTokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureTokenStorageProvider);
  return DioClient(tokenStorage: storage).dio;
});
