import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/network_providers.dart';

class AdminSnapshot {
  const AdminSnapshot(
      {required this.dashboard, required this.metrics, required this.dispatch});

  final Map<String, dynamic> dashboard;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> dispatch;
}

class AdminDispatchBundle {
  const AdminDispatchBundle({
    required this.orders,
    required this.overdueOrders,
    required this.tradeIns,
  });

  final List<OrderSummary> orders;
  final List<OrderSummary> overdueOrders;
  final List<Map<String, dynamic>> tradeIns;

  Set<int> get _overdueOrderIds =>
      overdueOrders.map((order) => order.id).toSet();

  bool _isNotOverdue(OrderSummary order) =>
      !_overdueOrderIds.contains(order.id);

  List<OrderSummary> get urgentAsapOrders => orders
      .where((order) =>
          order.deliveryMethod == 'asap' &&
          !order.isAcknowledged &&
          _isNotOverdue(order))
      .toList(growable: false);

  List<OrderSummary> get fulfillmentOrders => orders
      .where((order) =>
          (order.status == 'pending' || order.status == 'cash_needed') &&
          _isNotOverdue(order))
      .toList(growable: false);

  List<OrderSummary> get tradeOrders => orders
      .where((order) =>
          (order.status == 'trade_review' ||
              order.status == 'pending_counteroffer') &&
          _isNotOverdue(order))
      .toList(growable: false);

  List<Map<String, dynamic>> get activeTradeIns => tradeIns
      .where((entry) => !{'completed', 'rejected', 'cancelled'}
          .contains(asString(entry['status'])))
      .toList(growable: false);
}

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<AdminSnapshot> loadSnapshot() async {
    final results = await Future.wait([
      _getMap(ApiEndpoints.adminDashboard),
      _getMap(ApiEndpoints.adminMetrics),
      _getMap(ApiEndpoints.dispatch),
    ]);
    return AdminSnapshot(
      dashboard: results[0],
      metrics: results[1],
      dispatch: results[2],
    );
  }

  Future<AdminDispatchBundle> loadDispatchCenter() async {
    try {
      final responses = await Future.wait<Response<dynamic>>([
        _dio.get<dynamic>(ApiEndpoints.dispatch),
        _dio.get<dynamic>(ApiEndpoints.overdue),
        _dio.get<dynamic>(ApiEndpoints.tradeInAdmin),
      ]);
      return AdminDispatchBundle(
        orders:
            asMapList(responses[0].data).map(OrderSummary.fromJson).toList(),
        overdueOrders:
            asMapList(responses[1].data).map(OrderSummary.fromJson).toList(),
        tradeIns: asMapList(responses[2].data),
      );
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> listResource(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return asMapList(response.data);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> loadResourceMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return asMap(response.data);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> saveResource({
    required String collectionPath,
    required Map<String, dynamic> payload,
    Object? detailKey,
    bool usePut = false,
  }) async {
    try {
      final path = detailKey == null
          ? collectionPath
          : _detailPath(collectionPath, detailKey);
      final response = detailKey == null
          ? await _dio.post<dynamic>(path, data: payload)
          : usePut
              ? await _dio.put<dynamic>(path, data: payload)
              : await _dio.patch<dynamic>(path, data: payload);
      return asMap(response.data);
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<void> deleteResource(String collectionPath, Object detailKey) async {
    try {
      await _dio.delete<dynamic>(_detailPath(collectionPath, detailKey));
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> loadMetrics(String days) {
    return loadResourceMap(
      ApiEndpoints.adminMetrics,
      queryParameters: {'days': days},
    );
  }

  Future<Map<String, dynamic>> loadUsers({
    String search = '',
    int page = 1,
    int pageSize = 48,
  }) {
    return loadResourceMap(ApiEndpoints.adminUsers, queryParameters: {
      'search': search,
      'page': page,
      'page_size': pageSize,
    });
  }

  Future<Map<String, dynamic>> loadUserDetail(int id) {
    return loadResourceMap(ApiEndpoints.adminUserDetail(id));
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) {
    return listResource(ApiEndpoints.searchUsers,
        queryParameters: {'q': query});
  }

  Future<List<Map<String, dynamic>>> searchPosUsers(String query) {
    return listResource(
      ApiEndpoints.adminUserSearch,
      queryParameters: {'q': query},
    );
  }

  Future<Map<String, dynamic>> createPosOrder(Map<String, dynamic> payload) {
    return saveResource(
      collectionPath: ApiEndpoints.adminCreateOrder,
      payload: payload,
    );
  }

  Future<Map<String, dynamic>> grantCredit({
    required int userId,
    required String amount,
    String note = '',
  }) {
    return saveResource(
      collectionPath: ApiEndpoints.tradeInAdminGrantCredit,
      payload: {'user_id': userId, 'amount': amount, 'note': note},
    );
  }

  Future<Map<String, dynamic>> runTradeInAction({
    required int id,
    required String action,
    Map<String, dynamic> payload = const {},
  }) {
    final path = switch (action) {
      'approve' => ApiEndpoints.adminTradeInApprove(id),
      'review' => ApiEndpoints.adminTradeInReview(id),
      'complete' => ApiEndpoints.adminTradeInComplete(id),
      'reject' => ApiEndpoints.adminTradeInReject(id),
      _ => ApiEndpoints.adminTradeInDetail(id),
    };
    return saveResource(collectionPath: path, payload: payload);
  }

  Future<List<Map<String, dynamic>>> usersWithStrikes() {
    return listResource(ApiEndpoints.usersWithStrikes);
  }

  Future<List<Map<String, dynamic>>> strikesForUser(int userId) {
    return listResource(
      ApiEndpoints.strikes,
      queryParameters: {'user_id': userId},
    );
  }

  Future<Map<String, dynamic>> issueStrike({
    required int userId,
    required String reason,
  }) {
    return saveResource(
      collectionPath: ApiEndpoints.strikes,
      payload: {'user_id': userId, 'reason': reason},
    );
  }

  Future<void> deleteStrike(int id) {
    return deleteResource(ApiEndpoints.strikes, id);
  }

  Future<StoreSettings> updateStoreSettings(
      Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.settings}1/',
        data: payload,
      );
      return StoreSettings.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<List<RecurringTimeslot>> loadRecurringTimeslots() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.recurringTimeslots);
      return asMapList(response.data).map(RecurringTimeslot.fromJson).toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<RecurringTimeslot> saveRecurringTimeslot({
    int? id,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = id == null
          ? await _dio.post<Map<String, dynamic>>(
              ApiEndpoints.recurringTimeslots,
              data: payload,
            )
          : await _dio.patch<Map<String, dynamic>>(
              '${ApiEndpoints.recurringTimeslots}$id/',
              data: payload,
            );
      return RecurringTimeslot.fromJson(
          response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<void> deleteRecurringTimeslot(int id) async {
    try {
      await _dio.delete<dynamic>('${ApiEndpoints.recurringTimeslots}$id/');
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  String _detailPath(String collectionPath, Object detailKey) {
    final base = collectionPath.endsWith('/')
        ? collectionPath.substring(0, collectionPath.length - 1)
        : collectionPath;
    final encoded = Uri.encodeComponent('$detailKey');
    return '$base/$encoded/';
  }

  Future<OrderSummary> runDispatchAction({
    required int orderId,
    required String action,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.dispatch,
        data: {'order_id': orderId, 'action': action, ...extra},
      );
      return OrderSummary.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data ?? const {};
    } on DioException {
      return const {};
    }
  }
}

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository(ref.watch(dioProvider)));
final adminSnapshotProvider = FutureProvider<AdminSnapshot>(
    (ref) => ref.watch(adminRepositoryProvider).loadSnapshot());
final adminDispatchCenterProvider =
    FutureProvider.autoDispose<AdminDispatchBundle>(
        (ref) => ref.watch(adminRepositoryProvider).loadDispatchCenter());
final adminRecurringTimeslotsProvider =
    FutureProvider.autoDispose<List<RecurringTimeslot>>(
        (ref) => ref.watch(adminRepositoryProvider).loadRecurringTimeslots());
