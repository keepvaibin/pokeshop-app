import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../data/campaign_repository.dart';
import '../campaign_navigation.dart';

class StorefrontCampaignCarousel extends ConsumerWidget {
  const StorefrontCampaignCarousel({this.scope = 'global', super.key});

  final String scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignBannersProvider(scope));
    return campaigns.when(
      loading: () => const _StaticCampaignFallback(loading: true),
      error: (error, stackTrace) => const _StaticCampaignFallback(),
      data: (items) => items.isEmpty
          ? const _StaticCampaignFallback()
          : _CampaignPageView(campaigns: items),
    );
  }
}

class _CampaignPageView extends StatefulWidget {
  const _CampaignPageView({required this.campaigns});

  final List<StorefrontCampaignBanner> campaigns;

  @override
  State<_CampaignPageView> createState() => _CampaignPageViewState();
}

class _CampaignPageViewState extends State<_CampaignPageView> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _CampaignPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaigns.length != widget.campaigns.length) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.campaigns.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.campaigns.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).width >= 760 ? 360.0 : 330.0;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.campaigns.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) => _CampaignSlide(
              campaign: widget.campaigns[index],
            ),
          ),
          if (widget.campaigns.length > 1)
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0;
                      index < widget.campaigns.length;
                      index += 1)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: index == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: index == _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CampaignSlide extends StatelessWidget {
  const _CampaignSlide({required this.campaign});

  final StorefrontCampaignBanner campaign;

  @override
  Widget build(BuildContext context) {
    final ctaUrl = safeCampaignUri(campaign.ctaUrl);
    final ctaLabel = campaign.ctaLabel.isEmpty ? 'Shop Now' : campaign.ctaLabel;

    return Material(
      color: AppColors.pkmnText,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: () => context.go('/campaigns/${campaign.slug}'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 0.55,
                  child: PkNetworkImage(
                    imageUrl: campaign.heroImageUrl,
                    semanticLabel: campaign.title,
                    fit: BoxFit.cover,
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.pkmnText,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.35, -0.25),
                      radius: 1.2,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 32, 18, 108),
                  child: PkNetworkImage(
                    imageUrl: campaign.heroImageUrl,
                    semanticLabel: campaign.title,
                    fit: BoxFit.contain,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.88),
                          Colors.black.withValues(alpha: 0.38),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.46, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 128,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading(
                            size: 21, color: Colors.white),
                      ),
                      if (campaign.subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          campaign.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(
                              size: 12, color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: PkButton(
                label: ctaUrl == null ? 'See Post' : ctaLabel,
                variant: ctaUrl == null
                    ? PkButtonVariant.secondary
                    : PkButtonVariant.accent,
                onPressed: ctaUrl == null
                    ? () => context.go('/campaigns/${campaign.slug}')
                    : () => openCampaignUri(context, campaign.ctaUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticCampaignFallback extends StatelessWidget {
  const _StaticCampaignFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.8,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/other/laicho_banner.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (loading) ColoredBox(color: Colors.white.withValues(alpha: 0.35)),
        ],
      ),
    );
  }
}
