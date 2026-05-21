import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cart_icon_button.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../data/campaign_repository.dart';
import '../campaign_navigation.dart';
import '../widgets/campaign_rich_text.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignDetailProvider(slug));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign'),
        actions: const [CartIconButton()],
      ),
      body: campaign.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(campaignDetailProvider(slug)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 220),
              Text(
                'This campaign could not be loaded.',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(size: 18),
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(campaignDetailProvider(slug)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth >= 760 ? 736.0 : double.infinity;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go(
                                  item.productLineSlug == null
                                      ? '/'
                                      : '/${item.productLineSlug}'),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Back'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PkCard(
                            padding: EdgeInsets.zero,
                            child: InkWell(
                              onTap: safeCampaignUri(item.ctaUrl) == null
                                  ? null
                                  : () => openCampaignUri(context, item.ctaUrl),
                              child: SizedBox(
                                height: constraints.maxWidth >= 760 ? 220 : 150,
                                child: PkNetworkImage(
                                  imageUrl: item.heroImageUrl,
                                  semanticLabel: item.title,
                                  fit: BoxFit.contain,
                                  padding: const EdgeInsets.all(14),
                                  backgroundColor: AppColors.pkmnGrayLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Center(
                            child: SizedBox(
                              width: 64,
                              child: Divider(
                                thickness: 4,
                                color: AppColors.pkmnYellow,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading(size: 30),
                          ),
                          if (item.subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body(size: 15),
                            ),
                          ],
                          if (safeCampaignUri(item.ctaUrl) != null) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: PkButton(
                                label: item.ctaLabel.isEmpty
                                    ? 'Shop Now'
                                    : item.ctaLabel,
                                variant: PkButtonVariant.accent,
                                onPressed: () =>
                                    openCampaignUri(context, item.ctaUrl),
                              ),
                            ),
                          ],
                          if (item.body.trim().isNotEmpty) ...[
                            const SizedBox(height: 28),
                            DecoratedBox(
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              child: CampaignRichText(html: item.body),
                            ),
                          ],
                          if (safeCampaignUri(item.ctaUrl) != null) ...[
                            const SizedBox(height: 24),
                            PkButton(
                              label: item.ctaLabel.isEmpty
                                  ? 'Shop Now'
                                  : item.ctaLabel,
                              variant: PkButtonVariant.accent,
                              expand: true,
                              onPressed: () =>
                                  openCampaignUri(context, item.ctaUrl),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
