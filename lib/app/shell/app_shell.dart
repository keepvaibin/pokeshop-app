import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';

final adminClientPreviewProvider = StateProvider<bool>((ref) => false);

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final previewClient = ref.watch(adminClientPreviewProvider);
    final useAdminNav =
        auth.isAdmin && (!previewClient || location.startsWith('/admin'));
    final destinations = _destinations(isAdmin: useAdminNav);
    final selected =
        _selectedIndex(destinations, location, isAdmin: useAdminNav);
    final selectedIndex = selected < 0 ? 0 : selected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final content = auth.isAdmin
            ? Column(
                children: [
                  _AdminPreviewSwitch(
                    enabled: previewClient,
                    onChanged: (value) {
                      ref.read(adminClientPreviewProvider.notifier).state =
                          value;
                      context.go(value ? '/' : '/admin');
                    },
                  ),
                  Expanded(child: child),
                ],
              )
            : child;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  minWidth: 76,
                  backgroundColor: Colors.white,
                  indicatorColor: AppColors.pkmnBlueLight,
                  onDestinationSelected: (index) =>
                      context.go(destinations[index].path),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final item in destinations) item.railDestination
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.pkmnBorder),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: useAdminNav
              ? NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      context.go(destinations[index].path),
                  destinations: [
                    for (final item in destinations) item.navDestination
                  ],
                )
              : _ClientBottomBar(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onSelected: (index) => context.go(destinations[index].path),
                ),
        );
      },
    );
  }

  int _selectedIndex(List<_ShellDestination> destinations, String location,
      {required bool isAdmin}) {
    if (isAdmin) {
      if (location.startsWith('/admin/dispatch')) return 2;
      if (location.startsWith('/admin/shop') ||
          location.startsWith('/admin/search') ||
          location.startsWith('/admin/product') ||
          location.startsWith('/admin/cart') ||
          location.startsWith('/admin/checkout')) {
        return 3;
      }
      if (location.startsWith('/admin/settings')) return 4;
      if (location.startsWith('/admin/menu') ||
          location.startsWith('/admin/orders')) {
        return 1;
      }
    } else {
      if (location.startsWith('/orders')) return 1;
      if (location.startsWith('/shop') ||
          location.startsWith('/search') ||
          location.startsWith('/product') ||
          location.startsWith('/cart') ||
          location.startsWith('/checkout')) {
        return 2;
      }
      if (location.startsWith('/trade-in')) return 3;
      if (location.startsWith('/my-sctcg') ||
          location.startsWith('/settings')) {
        return 4;
      }
    }
    var bestIndex = -1;
    var bestLength = -1;
    for (var index = 0; index < destinations.length; index += 1) {
      final path = destinations[index].path;
      final matches = location == path || location.startsWith('$path/');
      if (matches && path.length > bestLength) {
        bestIndex = index;
        bestLength = path.length;
      }
    }
    return bestIndex;
  }

  List<_ShellDestination> _destinations({required bool isAdmin}) {
    if (isAdmin) {
      return const [
        _ShellDestination(
            path: '/admin',
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard),
        _ShellDestination(
            path: '/admin/menu',
            label: 'Menu',
            icon: Icons.apps_outlined,
            selectedIcon: Icons.apps),
        _ShellDestination(
            path: '/admin/dispatch',
            label: 'Dispatch',
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping),
        _ShellDestination(
            path: '/admin/shop',
            label: 'Shop',
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront),
        _ShellDestination(
            path: '/admin/settings',
            label: 'Settings',
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune),
      ];
    }
    return const [
      _ShellDestination(
          path: '/',
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home),
      _ShellDestination(
          path: '/orders',
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long),
      _ShellDestination(
          path: '/shop',
          label: 'Shop',
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag),
      _ShellDestination(
          path: '/trade-in',
          label: 'Trade',
          icon: Icons.style_outlined,
          selectedIcon: Icons.style),
      _ShellDestination(
          path: '/my-sctcg',
          label: 'My SCTCG',
          icon: Icons.person_outline,
          selectedIcon: Icons.person),
    ];
  }
}

class _AdminPreviewSwitch extends StatelessWidget {
  const _AdminPreviewSwitch({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.pkmnBlueLight : AppColors.pkmnGrayLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              Icon(
                enabled
                    ? Icons.visibility_outlined
                    : Icons.admin_panel_settings_outlined,
                size: 18,
                color:
                    enabled ? AppColors.pkmnBlueDark : AppColors.pkmnGrayDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  enabled ? 'Viewing customer app' : 'Admin mode',
                  style: AppTextStyles.label(
                    color: enabled
                        ? AppColors.pkmnBlueDark
                        : AppColors.pkmnGrayDark,
                  ),
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientBottomBar extends StatelessWidget {
  const _ClientBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.pkmnBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var index = 0; index < destinations.length; index += 1)
                Expanded(
                  child: _ClientBottomBarItem(
                    destination: destinations[index],
                    selected: selectedIndex == index,
                    elevated: index == 2,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientBottomBarItem extends StatelessWidget {
  const _ClientBottomBarItem({
    required this.destination,
    required this.selected,
    required this.elevated,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final bool elevated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.pkmnBlue : AppColors.pkmnGrayDark;
    final icon = Icon(selected ? destination.selectedIcon : destination.icon,
        color: elevated ? Colors.white : color, size: elevated ? 28 : 22);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: elevated ? 34 : 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (elevated)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.pkmnBlue : AppColors.pkmnText,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x260054A6),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(child: icon),
              )
            else ...[
              icon,
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(color: color).copyWith(fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  NavigationDestination get navDestination {
    return NavigationDestination(
        icon: _icon(icon), selectedIcon: _icon(selectedIcon), label: label);
  }

  NavigationRailDestination get railDestination {
    return NavigationRailDestination(
        icon: _icon(icon),
        selectedIcon: _icon(selectedIcon),
        label: Text(label, style: AppTextStyles.label()));
  }

  Widget _icon(IconData data) {
    return Icon(data);
  }
}
