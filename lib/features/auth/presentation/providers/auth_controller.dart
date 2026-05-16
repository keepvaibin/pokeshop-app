import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../notifications/data/push_notification_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/entities/app_user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState(
      {required this.status, this.user, this.errorMessage, this.busy = false});

  const AuthState.checking() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final bool busy;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith(
      {AuthStatus? status,
      AppUser? user,
      String? errorMessage,
      bool? busy,
      bool clearError = false}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      busy: busy ?? this.busy,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(pushNotificationServiceProvider),
  );
});

final pokemonIconsProvider = FutureProvider<List<PokemonIconOption>>(
    (ref) => ref.watch(authRepositoryProvider).pokemonIcons());

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._pushNotifications)
      : super(const AuthState.checking()) {
    unawaited(restore());
  }

  final AuthRepository _repository;
  final PushNotificationService _pushNotifications;

  Future<void> restore() async {
    final user = await _repository.restoreSession();
    state = user == null
        ? const AuthState(status: AuthStatus.unauthenticated)
        : AuthState(status: AuthStatus.authenticated, user: user);
    if (user != null) {
      unawaited(_pushNotifications.registerDeviceIfAllowed());
    }
  }

  Future<void> loginWithEmail(
      {required String email, required String password}) async {
    await _runAuthAction(
        () => _repository.loginWithEmail(email: email, password: password));
  }

  Future<void> loginWithGoogle() async {
    await _runAuthAction(_repository.loginWithGoogle);
  }

  Future<bool> validateAccessCode(String code) =>
      _repository.validateAccessCode(code);

  Future<void> registerWithAccessCode({
    required String email,
    required String password,
    required String accessCode,
    String firstName = '',
    String lastName = '',
  }) async {
    await _runAuthAction(
      () => _repository.registerWithAccessCode(
        email: email,
        password: password,
        accessCode: accessCode,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  Future<void> refreshUser() async {
    final user = await _repository.currentUser();
    state = state.copyWith(
        status: AuthStatus.authenticated, user: user, clearError: true);
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    final user = await _repository.updateProfile(payload);
    state = state.copyWith(user: user, clearError: true);
  }

  Future<void> logout() async {
    await _pushNotifications.unregisterCurrentDevice();
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _runAuthAction(Future<AppUser> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      unawaited(_pushNotifications.registerDeviceIfAllowed());
    } on AppException catch (error) {
      state = AuthState(
          status: AuthStatus.unauthenticated, errorMessage: error.message);
    } catch (error) {
      state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: _unexpectedMessage(error));
    }
  }

  String _unexpectedMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isNotEmpty && !message.startsWith('Instance of')) {
      return message;
    }
    return 'Unable to sign in. Check your connection and try again.';
  }
}
