import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../data/drop_repository.dart';

class MyDropsSection extends ConsumerWidget {
  const MyDropsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drops = ref.watch(myDropsProvider);
    return drops.when(
      loading: () => const _LoadingDropCard(),
      error: (error, stackTrace) => PkCard(
        child: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, color: AppColors.pkmnRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Drops could not be loaded.',
                  style: AppTextStyles.body(color: AppColors.pkmnRed)),
            ),
            TextButton(
              onPressed: () => ref.invalidate(myDropsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_activity_outlined,
                    color: AppColors.pkmnBlue),
                const SizedBox(width: 8),
                Text('Your Drops', style: AppTextStyles.heading(size: 21)),
              ],
            ),
            const SizedBox(height: 12),
            for (final drop in items) ...[
              _DropSummaryCard(drop: drop),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _LoadingDropCard extends StatelessWidget {
  const _LoadingDropCard();

  @override
  Widget build(BuildContext context) {
    return const PkCard(
      child: Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Checking your drops...'),
        ],
      ),
    );
  }
}

class _DropSummaryCard extends StatelessWidget {
  const _DropSummaryCard({required this.drop});

  final MyDropSummary drop;

  @override
  Widget build(BuildContext context) {
    final visibleOptions = drop.visibleOptions.take(3).toList();
    final expiry = drop.expiresAt == null
        ? ''
        : DateFormat('MMM d, h:mm a').format(drop.expiresAt!.toLocal());
    final needsChoice = drop.requiresSelection && !drop.hasConfirmedSelection;

    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drop.campaignName,
                        style: AppTextStyles.heading(size: 17)),
                    if (expiry.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Expires $expiry',
                          style: AppTextStyles.body(size: 12)),
                    ],
                  ],
                ),
              ),
              Icon(
                needsChoice
                    ? Icons.rule_folder_outlined
                    : Icons.verified_outlined,
                color:
                    needsChoice ? AppColors.pkmnYellowDark : AppColors.pkmnBlue,
              ),
            ],
          ),
          if (visibleOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in visibleOptions)
                  _OptionChip(label: option.title),
                if (drop.visibleOptions.length > visibleOptions.length)
                  _OptionChip(
                      label:
                          '+${drop.visibleOptions.length - visibleOptions.length}'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          PkButton(
            label: needsChoice ? 'Choose Groups' : 'View Drop',
            icon: Icon(needsChoice
                ? Icons.rule_folder_outlined
                : Icons.lock_open_outlined),
            expand: true,
            variant:
                needsChoice ? PkButtonVariant.accent : PkButtonVariant.primary,
            onPressed: () => context.go('/drops/claim/${drop.entitlementId}'),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pkmnBlueLight,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.pkmnBlue.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label(color: AppColors.pkmnBlueDark),
        ),
      ),
    );
  }
}
