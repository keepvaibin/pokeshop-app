import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/network_providers.dart';

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  Future<List<OrderSummary>> myOrders() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.myOrders);
      return asMapList(response.data).map(OrderSummary.fromJson).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<List<OrderSummary>> adminOrders() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.adminHistory);
      return asMapList(response.data).map(OrderSummary.fromJson).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<OrderSummary> orderDetail(String orderId) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiEndpoints.orderReceipt(orderId));
      return OrderSummary.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<OrderSummary> adminCancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cancelOrder(orderId),
        data: {'reason': reason},
      );
      return OrderSummary.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<OrderSummary> adminCancelOrderItems({
    required String orderId,
    required List<int> orderItemIds,
    required String reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.cancelOrderItems(orderId),
        data: {'order_item_ids': orderItemIds, 'reason': reason},
      );
      return OrderSummary.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
    (ref) => OrdersRepository(ref.watch(dioProvider)));
final myOrdersProvider = FutureProvider<List<OrderSummary>>(
    (ref) => ref.watch(ordersRepositoryProvider).myOrders());
final adminOrdersProvider = FutureProvider<List<OrderSummary>>(
    (ref) => ref.watch(ordersRepositoryProvider).adminOrders());
final orderDetailProvider = FutureProvider.family<OrderSummary, String>(
    (ref, orderId) => ref.watch(ordersRepositoryProvider).orderDetail(orderId));
