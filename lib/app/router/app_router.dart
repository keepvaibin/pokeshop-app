import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dispatch_screen.dart';
import '../../features/admin/presentation/screens/admin_metrics_screen.dart';
import '../../features/admin/presentation/screens/admin_pos_screen.dart';
import '../../features/admin/presentation/screens/admin_quick_menu_screen.dart';
import '../../features/admin/presentation/screens/admin_resource_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_strikes_screen.dart';
import '../../features/admin/presentation/screens/admin_trade_ins_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/account/presentation/screens/my_sctcg_screen.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/campaign/presentation/screens/campaign_detail_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/drops/presentation/screens/drop_claim_screen.dart';
import '../../features/home/presentation/screens/delivery_info_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/admin_orders_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shop/presentation/screens/search_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/trade_in/presentation/screens/trade_in_screen.dart';
import '../shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
              path: '/shop',
              builder: (context, state) => ShopScreen(
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/products',
              builder: (context, state) => ShopScreen(
                    title: 'Products',
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/new-releases',
              builder: (context, state) => ShopScreen(
                    title: 'New Releases',
                    initialSort: 'newest',
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/tcg',
              builder: (context, state) => ShopScreen(
                    title: 'TCG',
                    initialCategory: 'cards',
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/tcg/cards',
              builder: (context, state) => ShopScreen(
                    title: 'Cards',
                    initialCategory: 'cards',
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/tcg/boxes',
              builder: (context, state) => ShopScreen(
                    title: 'Boxes',
                    initialCategory: 'boxes',
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/tcg/accessories',
              builder: (context, state) => ShopScreen(
                    title: 'Accessories',
                    initialCategory: 'accessories',
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/category/:slug',
              builder: (context, state) => ShopScreen(
                  title: 'Category',
                  initialCategory: state.pathParameters['slug'],
                  initialSearch: _searchTextFrom(state),
                  initialFilters: _shopFiltersFrom(state))),
          GoRoute(
              path: '/search',
              builder: (context, state) => SearchScreen(
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/delivery-info',
              builder: (context, state) => const DeliveryInfoScreen()),
          GoRoute(
              path: '/product/:slug',
              builder: (context, state) => ProductDetailScreen(
                    slug: state.pathParameters['slug'] ?? '',
                    entitlementId: state.uri.queryParameters['entitlement'] ??
                        state.uri.queryParameters['entitlement_id'],
                    campaignItemId: int.tryParse(
                        state.uri.queryParameters['campaign_item'] ??
                            state.uri.queryParameters['campaign_item_id'] ??
                            ''),
                  )),
          GoRoute(
              path: '/drops/claim/:token',
              builder: (context, state) => DropClaimScreen(
                  entitlementId: state.pathParameters['token'] ?? '')),
          GoRoute(
              path: '/campaigns/:slug',
              builder: (context, state) => CampaignDetailScreen(
                  slug: state.pathParameters['slug'] ?? '')),
          GoRoute(
              path: '/cart', builder: (context, state) => const CartScreen()),
          GoRoute(
              path: '/checkout',
              builder: (context, state) => const CheckoutScreen()),
          GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen()),
          GoRoute(
              path: '/orders/:id',
              builder: (context, state) =>
                  OrderDetailScreen(orderId: state.pathParameters['id'] ?? '')),
          GoRoute(
              path: '/my-sctcg',
              builder: (context, state) => const MySctcgScreen()),
          GoRoute(
              path: '/admin/orders',
              builder: (context, state) => const AdminOrdersScreen()),
          GoRoute(
              path: '/admin/orders/:id',
              builder: (context, state) =>
                  OrderDetailScreen(orderId: state.pathParameters['id'] ?? '')),
          GoRoute(
              path: '/admin/menu',
              builder: (context, state) => const AdminQuickMenuScreen()),
          GoRoute(
              path: '/admin/pos',
              builder: (context, state) => const AdminPosScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (context, state) => const AdminUsersScreen()),
          GoRoute(
              path: '/admin/metrics',
              builder: (context, state) => const AdminMetricsScreen()),
          GoRoute(
              path: '/admin/dispatch',
              builder: (context, state) => const AdminDispatchScreen()),
          GoRoute(
              path: '/admin/inventory',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.inventory)),
          GoRoute(
              path: '/admin/cards',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.cards)),
          GoRoute(
              path: '/admin/categories',
              builder: (context, state) => const AdminTabbedResourceScreen(
                      title: 'Categories',
                      configs: [
                        AdminResourceConfigs.categories,
                        AdminResourceConfigs.subcategories,
                      ])),
          GoRoute(
              path: '/admin/promos',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.promos)),
          GoRoute(
              path: '/admin/campaigns',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.storefrontCampaigns)),
          GoRoute(
              path: '/admin/wanted',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.wanted)),
          GoRoute(
              path: '/admin/trade-ins',
              builder: (context, state) => const AdminTradeInsScreen()),
          GoRoute(
              path: '/admin/coupons',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.coupons)),
          GoRoute(
              path: '/admin/access-codes',
              builder: (context, state) => const AdminResourceScreen(
                  config: AdminResourceConfigs.accessCodes)),
          GoRoute(
              path: '/admin/strikes',
              builder: (context, state) => const AdminStrikesScreen()),
          GoRoute(
              path: '/admin/shop',
              builder: (context, state) => ShopScreen(
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/admin/search',
              builder: (context, state) => SearchScreen(
                    initialSearch: _searchTextFrom(state),
                    initialFilters: _shopFiltersFrom(state),
                  )),
          GoRoute(
              path: '/admin/product/:slug',
              builder: (context, state) => ProductDetailScreen(
                    slug: state.pathParameters['slug'] ?? '',
                    entitlementId: state.uri.queryParameters['entitlement'] ??
                        state.uri.queryParameters['entitlement_id'],
                    campaignItemId: int.tryParse(
                        state.uri.queryParameters['campaign_item'] ??
                            state.uri.queryParameters['campaign_item_id'] ??
                            ''),
                  )),
          GoRoute(
              path: '/admin/cart',
              builder: (context, state) => const CartScreen()),
          GoRoute(
              path: '/admin/checkout',
              builder: (context, state) => const CheckoutScreen()),
          GoRoute(
              path: '/admin/settings',
              builder: (context, state) => const AdminSettingsScreen()),
          GoRoute(
              path: '/trade-in',
              builder: (context, state) => const TradeInScreen()),
          GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen()),
          GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen()),
        ],
      ),
    ],
  );
});

String _searchTextFrom(GoRouterState state) {
  final params = state.uri.queryParameters;
  return params['q'] ?? params['search'] ?? '';
}

Map<String, String> _shopFiltersFrom(GoRouterState state) {
  final filters = Map<String, String>.from(state.uri.queryParameters);
  filters.remove('q');
  filters.remove('search');
  return filters;
}

String _withCurrentQuery(String path, GoRouterState state) {
  final query = state.uri.query;
  return query.isEmpty ? path : Uri(path: path, query: query).toString();
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
    ref.listen<bool>(adminClientPreviewProvider, (_, __) => notifyListeners());
  }

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    final adminClientPreview = ref.read(adminClientPreviewProvider);
    final path = state.matchedLocation;
    final isAuthRoute = path == '/login' || path == '/register';

    if (auth.status == AuthStatus.checking) {
      return path == '/splash' ? null : '/splash';
    }

    if (path == '/splash') {
      return auth.isAuthenticated ? (auth.isAdmin ? '/admin' : '/') : '/login';
    }

    if (path == '/' && auth.isAdmin && !adminClientPreview) {
      return '/admin';
    }

    if (auth.isAdmin && !adminClientPreview) {
      if (path == '/my-sctcg') return '/admin/settings';
      if (path == '/shop') return _withCurrentQuery('/admin/shop', state);
      if (path == '/search') return _withCurrentQuery('/admin/search', state);
      if (path == '/settings') return '/admin/settings';
      if (path == '/cart') return '/admin/cart';
      if (path == '/checkout') return '/admin/checkout';
      if (path.startsWith('/product/')) {
        return _withCurrentQuery(
            path.replaceFirst('/product/', '/admin/product/'), state);
      }
    }

    final protectedPaths = [
      '/checkout',
      '/orders',
      '/my-sctcg',
      '/trade-in',
      '/drops',
      '/settings',
      '/admin'
    ];
    final needsAuth = protectedPaths.any(path.startsWith);
    if (needsAuth && !auth.isAuthenticated) {
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }

    if (path.startsWith('/admin') && !auth.isAdmin) {
      return '/';
    }

    if (isAuthRoute && auth.isAuthenticated) {
      final from = state.uri.queryParameters['from'];
      if (from != null && from.isNotEmpty) return from;
      return auth.isAdmin ? '/admin' : '/';
    }

    return null;
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
