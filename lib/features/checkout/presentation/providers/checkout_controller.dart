import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/models/api_models.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../data/checkout_repository.dart';

class CheckoutState {
  const CheckoutState({
    this.step = 0,
    this.paymentMethod = '',
    this.deliveryMethod = '',
    this.timeslot,
    this.discordHandle = '',
    this.tradeCards = const [],
    this.tradeMode = 'all_or_nothing',
    this.buyIfTradeDenied = false,
    this.backupPaymentMethod = '',
    this.couponCode = '',
    this.coupon,
    this.useStoreCredit = false,
    this.submitting = false,
    this.errorMessage,
    this.placedOrder,
  });

  final int step;
  final String paymentMethod;
  final String deliveryMethod;
  final TimeslotSelection? timeslot;
  final String discordHandle;
  final List<TradeCardEntry> tradeCards;
  final String tradeMode;
  final bool buyIfTradeDenied;
  final String backupPaymentMethod;
  final String couponCode;
  final CouponValidation? coupon;
  final bool useStoreCredit;
  final bool submitting;
  final String? errorMessage;
  final OrderSummary? placedOrder;

  bool canSubmit(List<CartLine> lines) {
    if (lines.isEmpty || paymentMethod.isEmpty || deliveryMethod.isEmpty) {
      return false;
    }
    if (deliveryMethod == 'scheduled' && timeslot == null) {
      return false;
    }
    if ((paymentMethod == 'trade' || paymentMethod == 'cash_plus_trade') &&
        tradeCards.isEmpty) {
      return false;
    }
    return true;
  }

  CheckoutState copyWith({
    int? step,
    String? paymentMethod,
    String? deliveryMethod,
    TimeslotSelection? timeslot,
    bool clearTimeslot = false,
    String? discordHandle,
    List<TradeCardEntry>? tradeCards,
    String? tradeMode,
    bool? buyIfTradeDenied,
    String? backupPaymentMethod,
    String? couponCode,
    CouponValidation? coupon,
    bool? useStoreCredit,
    bool? submitting,
    String? errorMessage,
    OrderSummary? placedOrder,
    bool clearError = false,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      timeslot: clearTimeslot ? null : timeslot ?? this.timeslot,
      discordHandle: discordHandle ?? this.discordHandle,
      tradeCards: tradeCards ?? this.tradeCards,
      tradeMode: tradeMode ?? this.tradeMode,
      buyIfTradeDenied: buyIfTradeDenied ?? this.buyIfTradeDenied,
      backupPaymentMethod: backupPaymentMethod ?? this.backupPaymentMethod,
      couponCode: couponCode ?? this.couponCode,
      coupon: coupon ?? this.coupon,
      useStoreCredit: useStoreCredit ?? this.useStoreCredit,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      placedOrder: placedOrder ?? this.placedOrder,
    );
  }
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController(ref.watch(checkoutRepositoryProvider), ref);
});

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._repository, this._ref)
      : super(const CheckoutState());

  final CheckoutRepository _repository;
  final Ref _ref;

  void setStep(int step) {
    final next = step < 0
        ? 0
        : step > 6
            ? 6
            : step;
    state = state.copyWith(step: next);
  }

  void setPayment(String value) =>
      state = state.copyWith(paymentMethod: value, clearError: true);
  void setDelivery(String value) => state = state.copyWith(
      deliveryMethod: value,
      clearTimeslot: value != 'scheduled',
      clearError: true);
  void setTimeslot(TimeslotSelection? value) => state = value == null
      ? state.copyWith(clearTimeslot: true)
      : state.copyWith(timeslot: value, clearError: true);
  void setDiscordHandle(String value) =>
      state = state.copyWith(discordHandle: value);
  void setCouponCode(String value) =>
      state = state.copyWith(couponCode: value, clearError: true);
  void setUseStoreCredit(bool value) =>
      state = state.copyWith(useStoreCredit: value);
  void addTradeCard(TradeCardEntry card) =>
      state = state.copyWith(tradeCards: [...state.tradeCards, card]);
  void removeTradeCard(int index) => state =
      state.copyWith(tradeCards: [...state.tradeCards]..removeAt(index));

  Future<void> validateCoupon() async {
    final lines = _ref.read(cartControllerProvider).lines;
    if (state.couponCode.trim().isEmpty) return;
    try {
      final coupon = await _repository.validateCoupon(
          code: state.couponCode,
          items: lines,
          paymentMethod: state.paymentMethod);
      state = state.copyWith(coupon: coupon, clearError: true);
    } on AppException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    }
  }

  Future<void> placeOrder() async {
    final cart = _ref.read(cartControllerProvider);
    if (!state.canSubmit(cart.lines)) {
      state = state.copyWith(
          errorMessage:
              'Complete each checkout step before placing your order.');
      return;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final order = await _repository.placeOrder(
        CheckoutPayload(
          items: cart.lines,
          paymentMethod: state.paymentMethod,
          deliveryMethod: state.deliveryMethod,
          timeslot: state.timeslot,
          discordHandle: state.discordHandle,
          tradeCards: state.tradeCards,
          tradeMode: state.tradeMode,
          buyIfTradeDenied: state.buyIfTradeDenied,
          backupPaymentMethod: state.backupPaymentMethod,
          couponCode: state.couponCode,
          useStoreCredit: state.useStoreCredit,
        ),
      );
      await _ref.read(cartControllerProvider.notifier).clear();
      state = state.copyWith(submitting: false, placedOrder: order);
    } on AppException catch (error) {
      state = state.copyWith(submitting: false, errorMessage: error.message);
    }
  }
}
