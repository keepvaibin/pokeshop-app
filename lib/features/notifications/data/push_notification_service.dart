import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_providers.dart';

enum PushPermissionState { unavailable, granted, provisional, denied }

class PushPermissionResult {
  const PushPermissionResult(this.state, [this.message = '']);

  final PushPermissionState state;
  final String message;

  bool get canRegister =>
      state == PushPermissionState.granted ||
      state == PushPermissionState.provisional;
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(dio: ref.watch(dioProvider));
});

class PushNotificationService {
  PushNotificationService({required Dio dio}) : _dio = dio;

  final Dio _dio;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<PushPermissionResult> requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      return _resultForStatus(settings.authorizationStatus);
    } catch (error) {
      debugPrint('Push permission request skipped: $error');
      return const PushPermissionResult(
        PushPermissionState.unavailable,
        'Notifications are not available on this build yet.',
      );
    }
  }

  Future<void> registerDeviceIfAllowed() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final result = _resultForStatus(settings.authorizationStatus);
      if (!result.canRegister) return;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
      _tokenRefreshSubscription ??=
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _registerToken(token).catchError((error) {
          debugPrint('Push token refresh registration skipped: $error');
        });
      });
    } catch (error) {
      debugPrint('Push device registration skipped: $error');
    }
  }

  Future<void> _registerToken(String token) {
    return _dio.post<Map<String, dynamic>>(
      ApiEndpoints.pushDevices,
      data: {
        'token': token,
        'platform': _platformLabel,
        'enabled': true,
      },
    );
  }

  Future<void> unregisterCurrentDevice() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.pushDevices,
        data: {'token': token},
      );
    } catch (error) {
      debugPrint('Push device unregister skipped: $error');
    }
  }

  PushPermissionResult _resultForStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return const PushPermissionResult(
          PushPermissionState.granted,
          'Notifications are on. We will register this device after sign-in.',
        );
      case AuthorizationStatus.provisional:
        return const PushPermissionResult(
          PushPermissionState.provisional,
          'Quiet notifications are on. We will register this device after sign-in.',
        );
      case AuthorizationStatus.denied:
        return const PushPermissionResult(
          PushPermissionState.denied,
          'Notifications are off. You can enable them later in system settings.',
        );
      case AuthorizationStatus.notDetermined:
        return const PushPermissionResult(PushPermissionState.denied);
    }
  }

  String get _platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}