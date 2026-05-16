abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.santacruztcg.com/api',
  );

  static const String token = '/token/';
  static const String tokenRefresh = '/token/refresh/';

  static const String googleAuth = '/auth/google/';
  static const String emailLogin = '/auth/login/';
  static const String register = '/auth/register/';
  static const String validateAccessCode = '/auth/validate-access-code/';
  static const String currentUser = '/auth/user/';
  static const String profile = '/auth/profile/';
  static const String discordInitiate = '/auth/discord/initiate/';
  static const String pokemonIcons = '/auth/pokemon-icons/';
  static const String myStrikes = '/auth/my-strikes/';
  static const String pushDevices = '/auth/push-devices/';

  static const String items = '/inventory/items/';
  static const String itemFacets = '/inventory/items/facets/';
  static const String categories = '/inventory/categories/';
  static const String subcategories = '/inventory/subcategories/';
  static const String homepageSections = '/inventory/homepage-sections/';
  static const String settings = '/inventory/settings/';
  static const String recurringTimeslots = '/inventory/recurring-timeslots/';
  static const String accessCodes = '/inventory/access-codes/';
  static const String promoBanners = '/inventory/promo-banners/';
  static const String adminCards = '/inventory/admin/cards/';
  static const String adminCardsSyncProperties =
      '/inventory/admin/cards/sync-properties/';
  static const String tcgInventorySearch = '/inventory/tcg-inventory-search/';
  static const String tcgSearch = '/inventory/tcg-search/';
  static const String wantedCards = '/inventory/wanted/';

  static const String cart = '/orders/cart/';
  static const String cartCheck = '/orders/cart/check/';
  static const String cartSync = '/orders/cart/sync/';
  static const String checkout = '/orders/checkout/';
  static const String myOrders = '/orders/my-orders/';
  static const String activeTimeslots = '/orders/active-timeslots/';
  static const String purchaseLimits = '/orders/purchase-limits/';
  static const String validateCoupon = '/orders/validate-coupon/';
  static const String coupons = '/orders/coupons/';
  static const String respondCounteroffer = '/orders/respond-counteroffer/';
  static const String rescheduleOrder = '/orders/reschedule/';
  static const String adminDashboard = '/orders/admin-dashboard/';
  static const String adminMetrics = '/orders/admin-metrics/';
  static const String dispatch = '/orders/dispatch/';
  static const String overdue = '/orders/overdue/';
  static const String adminHistory = '/orders/admin-history/';
  static const String adminCreateOrder = '/orders/admin/create-order/';
  static const String adminPosInventory = '/orders/admin/pos-inventory/';
  static const String adminUserSearch = '/orders/admin/users/search/';

  static const String adminUsers = '/auth/admin/users/';
  static const String searchUsers = '/auth/search-users/';
  static const String usersWithStrikes = '/auth/users-with-strikes/';
  static const String strikes = '/auth/strikes/';

  static const String tradeIns = '/trade-ins/';
  static const String tradeInWallet = '/trade-ins/wallet/';
  static const String tradeInAdmin = '/trade-ins/admin/';
  static const String tradeInAdminGrantCredit =
      '/trade-ins/admin/grant-credit/';

  static String itemBySlug(String slug) => '/inventory/items/$slug/';
  static String itemReorderImages(String slug) =>
      '/inventory/items/$slug/reorder-images/';
  static String categoryBySlug(String slug) => '/inventory/categories/$slug/';
  static String orderReceipt(String orderId) => '/orders/receipt/$orderId/';
  static String mergeCart(String orderId) => '/orders/$orderId/merge-cart/';
  static String cancelOrder(String orderId) => '/orders/$orderId/cancel/';
  static String cancelOrderItems(String orderId) =>
      '/orders/$orderId/cancel-items/';
  static String couponDetail(int id) => '/orders/coupons/$id/';
  static String adminUserDetail(int id) => '/auth/admin/users/$id/';
  static String strikeDetail(int id) => '/auth/strikes/$id/';
  static String tradeInDetail(int id) => '/trade-ins/$id/';
  static String adminTradeInDetail(int id) => '/trade-ins/admin/$id/';
  static String adminTradeInApprove(int id) => '/trade-ins/admin/$id/approve/';
  static String tradeInCounteroffer(int id) =>
      '/trade-ins/$id/respond-counteroffer/';
  static String adminTradeInReview(int id) => '/trade-ins/admin/$id/review/';
  static String adminTradeInComplete(int id) =>
      '/trade-ins/admin/$id/complete/';
  static String adminTradeInReject(int id) => '/trade-ins/admin/$id/reject/';
}
