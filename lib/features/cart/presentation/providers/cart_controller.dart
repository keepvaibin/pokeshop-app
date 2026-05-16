import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../../core/network/network_providers.dart';

enum CartChangeResult { updated, limited }

class CartState {
  const CartState(
      {this.lines = const [], this.syncing = false, this.errorMessage});

  final List<CartLine> lines;
  final bool syncing;
  final String? errorMessage;

  int get totalQuantity => lines.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => lines.fold(0, (sum, line) => sum + line.subtotal);
  int quantityFor(int itemId) {
    for (final line in lines) {
      if (line.item.id == itemId) return line.quantity;
    }
    return 0;
  }

  CartState copyWith(
      {List<CartLine>? lines,
      bool? syncing,
      String? errorMessage,
      bool clearError = false}) {
    return CartState(
      lines: lines ?? this.lines,
      syncing: syncing ?? this.syncing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  final controller = CartController(ref.watch(dioProvider), ref);
  unawaited(controller.restore());
  return controller;
});

class CartController extends StateNotifier<CartState> {
  CartController(this._dio, this._ref) : super(const CartState());

  static const _storageKey = 'pokeshop_cart_v1';
  static const limitMessage = 'There is a limit for this item.';

  final Dio _dio;
  final Ref _ref;

  Future<void> restore() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    state = state.copyWith(
        lines: decoded
            .whereType<Map>()
            .map((entry) => CartLine.fromJson(Map<String, dynamic>.from(entry)))
            .toList());
  }

  Future<CartChangeResult> add(ProductItem item, {int quantity = 1}) async {
    final existing =
        state.lines.where((line) => line.item.id == item.id).firstOrNull;
    return setQuantity(item, (existing?.quantity ?? 0) + quantity);
  }

  Future<CartChangeResult> setQuantity(ProductItem item, int quantity) async {
    if (quantity <= 0) {
      final next =
          state.lines.where((line) => line.item.id != item.id).toList();
      state = state.copyWith(lines: next, clearError: true);
      await _persist();
      return CartChangeResult.updated;
    }

    if (!item.inStock) {
      state = state.copyWith(errorMessage: limitMessage);
      return CartChangeResult.limited;
    }

    final localLimit = item.localQuantityLimit;
    if (localLimit != null && quantity > localLimit) {
      state = state.copyWith(errorMessage: limitMessage);
      return CartChangeResult.limited;
    }

    final serverAllowed = await _serverAllows(item.id, quantity);
    if (!serverAllowed) {
      state = state.copyWith(errorMessage: limitMessage);
      return CartChangeResult.limited;
    }

    final existing =
        state.lines.where((line) => line.item.id == item.id).firstOrNull;
    final lines = [...state.lines];
    if (existing == null) {
      lines.add(CartLine(item: item, quantity: quantity));
    } else {
      final index = lines.indexOf(existing);
      lines[index] = existing.copyWith(item: item, quantity: quantity);
    }
    state = state.copyWith(lines: lines, clearError: true);
    await _persist();
    return CartChangeResult.updated;
  }

  Future<CartChangeResult> updateQuantity(int itemId, int quantity) async {
    final existing =
        state.lines.where((line) => line.item.id == itemId).firstOrNull;
    if (existing == null) return CartChangeResult.updated;
    return setQuantity(existing.item, quantity);
  }

  Future<CartChangeResult> remove(int itemId) => updateQuantity(itemId, 0);

  Future<void> clear() async {
    state = state.copyWith(lines: const [], clearError: true);
    await _persist();
  }

  Future<void> syncToServer() async {
    if (state.lines.isEmpty) return;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      await _dio.post(ApiEndpoints.cartSync, data: {
        'items': state.lines.map((line) => line.toCheckoutJson()).toList()
      });
      state = state.copyWith(syncing: false);
    } on DioException catch (error) {
      state = state.copyWith(
          syncing: false,
          errorMessage:
              error.response?.data?.toString() ?? 'Cart sync failed.');
    }
  }

  Future<bool> _serverAllows(int itemId, int quantity) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cartCheck,
        data: {'item_id': itemId, 'quantity': quantity},
      );
      return asBool(response.data?['allowed'], fallback: true);
    } on DioException {
      return true;
    }
  }

  Future<void> _persist() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_storageKey,
        jsonEncode(state.lines.map((line) => line.toJson()).toList()));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
