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
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
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
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
              path: '/shop', builder: (context, state) => const ShopScreen()),
          GoRoute(
              path: '/products',
              builder: (context, state) => const ShopScreen(title: 'Products')),
          GoRoute(
              path: '/new-releases',
              builder: (context, state) => const ShopScreen(
                  title: 'New Releases', initialSort: 'newest')),
          GoRoute(
              path: '/tcg',
              builder: (context, state) =>
                  const ShopScreen(title: 'TCG', initialCategory: 'cards')),
          GoRoute(
              path: '/tcg/cards',
              builder: (context, state) =>
                  const ShopScreen(title: 'Cards', initialCategory: 'cards')),
          GoRoute(
              path: '/tcg/boxes',
              builder: (context, state) =>
                  const ShopScreen(title: 'Boxes', initialCategory: 'boxes')),
          GoRoute(
              path: '/tcg/accessories',
              builder: (context, state) => const ShopScreen(
                  title: 'Accessories', initialCategory: 'accessories')),
          GoRoute(
              path: '/category/:slug',
              builder: (context, state) => ShopScreen(
                  title: 'Category',
                  initialCategory: state.pathParameters['slug'])),
          GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen()),
          GoRoute(
              path: '/delivery-info',
              builder: (context, state) => const DeliveryInfoScreen()),
          GoRoute(
              path: '/product/:slug',
              builder: (context, state) => ProductDetailScreen(
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
              builder: (context, state) => const ShopScreen()),
          GoRoute(
              path: '/admin/search',
              builder: (context, state) => const SearchScreen()),
          GoRoute(
              path: '/admin/product/:slug',
              builder: (context, state) => ProductDetailScreen(
                  slug: state.pathParameters['slug'] ?? '')),
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
      if (path == '/shop') return '/admin/shop';
      if (path == '/search') return '/admin/search';
      if (path == '/settings') return '/admin/settings';
      if (path == '/cart') return '/admin/cart';
      if (path == '/checkout') return '/admin/checkout';
      if (path.startsWith('/product/')) {
        return path.replaceFirst('/product/', '/admin/product/');
      }
    }

    final protectedPaths = [
      '/checkout',
      '/orders',
      '/my-sctcg',
      '/trade-in',
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
