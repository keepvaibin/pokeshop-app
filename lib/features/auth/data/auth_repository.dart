import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/entities/app_user.dart';

class PokemonIconOption {
  const PokemonIconOption({
    required this.id,
    required this.filename,
    required this.displayName,
    this.region = '',
  });

  final int id;
  final String filename;
  final String displayName;
  final String region;

  factory PokemonIconOption.fromJson(Map<String, dynamic> json) {
    return PokemonIconOption(
      id: asInt(json['id']),
      filename: asString(json['filename']),
      displayName: asString(json['display_name'], fallback: 'Pokemon'),
      region: asString(json['region']),
    );
  }
}

class AuthRepository {
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '47617010879-0ibkhq97l1e875fhj74v27ojinfd3nrk.apps.googleusercontent.com',
  );
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  AuthRepository(
      {required Dio dio,
      required SecureTokenStorage tokenStorage,
      GoogleSignIn? googleSignIn})
      : _dio = dio,
        _tokenStorage = tokenStorage,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              hostedDomain: 'ucsc.edu',
              clientId: _platformClientId,
              serverClientId:
                  _googleWebClientId.isEmpty ? null : _googleWebClientId,
            );

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;

  static String? get _platformClientId {
    if (kIsWeb) {
      return _googleWebClientId.isEmpty ? null : _googleWebClientId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _googleIosClientId.isEmpty ? null : _googleIosClientId;
    }
    return null;
  }

  Future<AppUser?> restoreSession() async {
    final access = await _tokenStorage.readAccessToken();
    if (access == null || access.isEmpty) return null;
    try {
      return currentUser();
    } on AppException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AppUser> currentUser() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.currentUser);
      return AppUser.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<AppUser> loginWithEmail(
      {required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.emailLogin,
        data: {'email': email.trim(), 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      return _storeTokensAndUser(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<AppUser> loginWithGoogle() async {
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AppException('Google sign-in was cancelled.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppException(
            'Google did not return an ID token. Confirm the mobile app is using the backend Google web client ID.');
      }
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.googleAuth,
        data: {'token': idToken},
        options: Options(extra: {'skipAuth': true}),
      );
      return _storeTokensAndUser(response.data ?? const <String, dynamic>{});
    } on PlatformException catch (error) {
      throw AppException(_googlePlatformMessage(error), details: error.details);
    } on DioException catch (error) {
      final appError = AppException.fromDio(error);
      throw AppException(_googleApiMessage(appError),
          statusCode: appError.statusCode, details: appError.details);
    }
  }

  Future<bool> validateAccessCode(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.validateAccessCode,
        data: {'access_code': code.trim(), 'code': code.trim()},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = response.data ?? const <String, dynamic>{};
      return asBool(data['valid'], fallback: true);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<AppUser> registerWithAccessCode({
    required String email,
    required String password,
    required String accessCode,
    String firstName = '',
    String lastName = '',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'password': password,
          'access_code': accessCode.trim(),
          'code': accessCode.trim(),
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
        options: Options(extra: {'skipAuth': true}),
      );
      return _storeTokensAndUser(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<AppUser> updateProfile(Map<String, dynamic> payload) async {
    try {
      await _dio.patch<Map<String, dynamic>>(ApiEndpoints.profile,
          data: payload);
      return currentUser();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<Uri> startDiscordLink({String nextPath = '/settings'}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.discordInitiate,
        queryParameters: {'next': nextPath},
      );
      final url = asString(response.data?['authorization_url']);
      if (url.isEmpty) {
        throw const AppException('Discord authorization URL was not returned.');
      }
      return Uri.parse(url);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    } on FormatException {
      throw const AppException(
          'Discord returned an invalid authorization URL.');
    }
  }

  Future<List<PokemonIconOption>> pokemonIcons() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.pokemonIcons);
      return asMapList(response.data)
          .map(PokemonIconOption.fromJson)
          .where((icon) => icon.filename.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<void> logout() async {
    await Future.wait([_googleSignIn.signOut(), _tokenStorage.clear()]);
  }

  Future<AppUser> _storeTokensAndUser(Map<String, dynamic> data) async {
    final access = (data['access'] ?? data['access_token'])?.toString();
    final refresh = (data['refresh'] ?? data['refresh_token'])?.toString();
    if (access != null && refresh != null) {
      await _tokenStorage
          .saveTokens(TokenPair(accessToken: access, refreshToken: refresh));
    }

    final userData = asMap(data['user']);
    if (userData.isNotEmpty) return AppUser.fromJson(userData);
    return currentUser();
  }

  String _googlePlatformMessage(PlatformException error) {
    final raw = '${error.code} ${error.message ?? ''} ${error.details ?? ''}'
        .toLowerCase();
    if (error.code == GoogleSignIn.kSignInCanceledError) {
      return 'Google sign-in was cancelled.';
    }
    if (error.code == GoogleSignIn.kNetworkError) {
      return 'Google Sign-In could not reach Google. Check your connection and try again.';
    }
    if (error.code == GoogleSignIn.kSignInFailedError ||
        raw.contains('api exception: 10')) {
      return 'Google Sign-In is not configured for this Android build yet. Register package com.santacruztcg.pokeshop_app and its SHA-1 in Google Cloud, then retry.';
    }
    return 'Google Sign-In failed: ${error.message ?? error.code}';
  }

  String _googleApiMessage(AppException error) {
    return switch (error.message) {
      'Invalid domain' =>
        'This Google account is not in the UCSC domain. Please use your @ucsc.edu Google account.',
      'Invalid token' =>
        'Google token validation failed. Confirm the mobile and backend Google client IDs match, then retry.',
      _ => 'Google login failed: ${error.message}',
    };
  }
}
