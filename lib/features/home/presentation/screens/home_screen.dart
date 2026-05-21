import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_announcement_banner.dart';
import '../../../../core/widgets/cart_icon_button.dart';
import '../../../campaign/data/campaign_repository.dart';
import '../../../campaign/presentation/widgets/campaign_carousel.dart';
import '../../../shop/data/shop_repository.dart';
import '../../../shop/presentation/widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeDataProvider);

    return home.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeDataProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 240),
              Center(child: Text('$error', textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
      data: (data) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SCTCG'),
            actions: [
              IconButton(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search)),
              const CartIconButton(),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeDataProvider);
              ref.invalidate(campaignBannersProvider('global'));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                PkAnnouncementBanner(message: data.settings.storeAnnouncement),
                const StorefrontCampaignCarousel(),
                _StorefrontHome(data: data),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StorefrontHome extends StatelessWidget {
  const _StorefrontHome({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductStrip(title: 'New Arrivals', items: data.newArrivals),
          const SizedBox(height: 24),
          _ProductStrip(title: 'All Products', items: data.items),
        ],
      ),
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip({required this.title, required this.items});

  final String title;
  final List items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.heading(size: 22)),
            TextButton(
                onPressed: () => context.go('/shop'),
                child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 330,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length > 12 ? 12 : items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
                width: 210,
                child: ProductCard(item: items[index], compact: true)),
          ),
        ),
      ],
    );
  }
}
