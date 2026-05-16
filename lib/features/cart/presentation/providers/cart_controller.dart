import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/network_providers.dart';

class CartState {
  const CartState(
      {this.lines = const [], this.syncing = false, this.errorMessage});

  final List<CartLine> lines;
  final bool syncing;
  final String? errorMessage;

  int get totalQuantity => lines.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => lines.fold(0, (sum, line) => sum + line.subtotal);

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

  Future<void> add(ProductItem item, {int quantity = 1}) async {
    final existing =
        state.lines.where((line) => line.item.id == item.id).firstOrNull;
    final lines = [...state.lines];
    final maxQuantity = item.stockQuantity <= 0 ? quantity : item.stockQuantity;
    if (existing == null) {
      lines.add(CartLine(item: item, quantity: quantity.clamp(1, maxQuantity)));
    } else {
      final index = lines.indexOf(existing);
      lines[index] = existing.copyWith(
          quantity: (existing.quantity + quantity).clamp(1, maxQuantity));
    }
    state = state.copyWith(lines: lines, clearError: true);
    await _persist();
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    final next = state.lines
        .map((line) {
          if (line.item.id != itemId) return line;
          final maxQuantity =
              line.item.stockQuantity <= 0 ? quantity : line.item.stockQuantity;
          return line.copyWith(quantity: quantity.clamp(0, maxQuantity));
        })
        .where((line) => line.quantity > 0)
        .toList();
    state = state.copyWith(lines: next, clearError: true);
    await _persist();
  }

  Future<void> remove(int itemId) => updateQuantity(itemId, 0);

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

  Future<void> _persist() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_storageKey,
        jsonEncode(state.lines.map((line) => line.toJson()).toList()));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
