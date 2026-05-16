import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pk_shimmer.dart';

class PkNetworkImage extends StatelessWidget {
  const PkNetworkImage({
    required this.imageUrl,
    required this.semanticLabel,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = AppColors.pkmnGrayLight,
    this.borderRadius = BorderRadius.zero,
    this.fallbackIconSize = 36,
    super.key,
  });

  final String? imageUrl;
  final String semanticLabel;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: padding,
          child: _ImageBody(
            imageUrl: imageUrl,
            semanticLabel: semanticLabel,
            fit: fit,
            fallbackIconSize: fallbackIconSize,
          ),
        ),
      ),
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.imageUrl,
    required this.semanticLabel,
    required this.fit,
    required this.fallbackIconSize,
  });

  final String? imageUrl;
  final String semanticLabel;
  final BoxFit fit;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _FallbackIcon(size: fallbackIconSize);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => PkShimmer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _FallbackIcon(
        size: fallbackIconSize,
        broken: true,
      ),
      imageBuilder: (context, provider) => Semantics(
        label: semanticLabel,
        image: true,
        child: Image(image: provider, fit: fit),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.size, this.broken = false});

  final double size;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        broken ? Icons.broken_image_outlined : Icons.image_outlined,
        size: size,
        color: AppColors.pkmnGrayDark,
      ),
    );
  }
}
