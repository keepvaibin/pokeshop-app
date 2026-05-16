import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/json_helpers.dart';
import '../../../core/network/network_providers.dart';

class TradeInRepository {
  TradeInRepository(this._dio);

  final Dio _dio;

  Future<List<TradeInRequestSummary>> listRequests() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.tradeIns);
      return asMapList(response.data)
          .map(TradeInRequestSummary.fromJson)
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<WalletSummary> wallet() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.tradeInWallet);
      return WalletSummary.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<void> submit({
    required TimeslotSelection timeslot,
    required List<TradeCardEntry> cards,
    required String payoutType,
    String cashPaymentMethod = '',
    String notes = '',
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.tradeIns,
        data: {
          'submission_method': 'in_store_dropoff',
          'payout_type': payoutType,
          'cash_payment_method': payoutType == 'cash' ? cashPaymentMethod : '',
          'recurring_timeslot': timeslot.recurringTimeslotId,
          'pickup_date': timeslot.pickupDate,
          'customer_notes': notes,
          'items': cards.map((card) => card.toJson()).toList(),
        },
      );
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

final tradeInRepositoryProvider = Provider<TradeInRepository>(
    (ref) => TradeInRepository(ref.watch(dioProvider)));
final tradeInHistoryProvider = FutureProvider<List<TradeInRequestSummary>>(
    (ref) => ref.watch(tradeInRepositoryProvider).listRequests());
final walletProvider = FutureProvider<WalletSummary>(
    (ref) => ref.watch(tradeInRepositoryProvider).wallet());
