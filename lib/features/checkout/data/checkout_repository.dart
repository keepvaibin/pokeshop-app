import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/models/api_models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/network_providers.dart';

class CheckoutPayload {
  const CheckoutPayload({
    required this.items,
    required this.paymentMethod,
    required this.deliveryMethod,
    this.timeslot,
    this.discordHandle = '',
    this.tradeCards = const [],
    this.tradeMode = 'all_or_nothing',
    this.buyIfTradeDenied = false,
    this.backupPaymentMethod = '',
    this.couponCode = '',
    this.useStoreCredit = false,
  });

  final List<CartLine> items;
  final String paymentMethod;
  final String deliveryMethod;
  final TimeslotSelection? timeslot;
  final String discordHandle;
  final List<TradeCardEntry> tradeCards;
  final String tradeMode;
  final bool buyIfTradeDenied;
  final String backupPaymentMethod;
  final String couponCode;
  final bool useStoreCredit;

  Map<String, dynamic> toJson() => {
        'items': items.map((line) => line.toCheckoutJson()).toList(),
        'payment_method': paymentMethod,
        'delivery_method': deliveryMethod,
        'recurring_timeslot': timeslot?.recurringTimeslotId,
        'recurring_timeslot_id': timeslot?.recurringTimeslotId,
        'pickup_date': timeslot?.pickupDate,
        'discord_handle': discordHandle,
        'trade_cards': tradeCards.map((card) => card.toJson()).toList(),
        'trade_mode': tradeMode,
        'buy_if_trade_denied': buyIfTradeDenied,
        'backup_payment_method': backupPaymentMethod,
        'coupon_code': couponCode.trim(),
        'use_store_credit': useStoreCredit,
      };
}

class CheckoutRepository {
  CheckoutRepository(this._dio);

  final Dio _dio;

  Future<CouponValidation> validateCoupon(
      {required String code,
      required List<CartLine> items,
      required String paymentMethod}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.validateCoupon,
        data: {
          'code': code.trim(),
          'coupon_code': code.trim(),
          'payment_method': paymentMethod,
          'items': items.map((line) => line.toCheckoutJson()).toList(),
        },
      );
      return CouponValidation.fromJson(
          response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Future<OrderSummary> placeOrder(CheckoutPayload payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.checkout,
          data: payload.toJson());
      return OrderSummary.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
    (ref) => CheckoutRepository(ref.watch(dioProvider)));
