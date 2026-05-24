import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cart_icon_button.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../cart/presentation/widgets/cart_quantity_control.dart';
import '../../data/drop_repository.dart';

class DropClaimScreen extends ConsumerStatefulWidget {
  const DropClaimScreen({required this.entitlementId, super.key});

  final String entitlementId;

  @override
  ConsumerState<DropClaimScreen> createState() => _DropClaimScreenState();
}

class _DropClaimScreenState extends ConsumerState<DropClaimScreen> {
  final Map<String, int> _selectedByGroup = {};
  bool _submitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final claim = ref.watch(dropClaimProvider(widget.entitlementId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drop'),
        actions: const [CartIconButton()],
      ),
      body: claim.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DropError(
          message: '$error',
          onRefresh: () async =>
              ref.invalidate(dropClaimProvider(widget.entitlementId)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dropClaimProvider(widget.entitlementId));
            ref.invalidate(myDropsProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth >= 760 ? 720.0 : double.infinity;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _bodyFor(data),
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

  Widget _bodyFor(DropClaim claim) {
    if (claim.allPurchased) {
      return _StateCard(
        icon: Icons.check_circle_outline,
        title: 'Drop Complete',
        message: 'Your selected items have already been checked out.',
        actionLabel: 'View Orders',
        onAction: () => context.go('/orders'),
      );
    }

    if (!claim.isActive) {
      return _StateCard(
        icon: Icons.lock_clock_outlined,
        title: 'Drop Unavailable',
        message: claim.isExpired
            ? 'This drop invite has expired.'
            : 'This drop invite is no longer active.',
        actionLabel: 'Back Home',
        onAction: () => context.go('/'),
      );
    }

    if (claim.requiresSelection && !claim.hasConfirmedSelection) {
      return _SelectionBody(
        claim: claim,
        selectedByGroup: _selectedByGroup,
        submitting: _submitting,
        errorMessage: _errorMessage,
        onToggle: _toggleOption,
        onConfirm: () => _confirmSelection(claim),
      );
    }

    return _UnlockedBody(claim: claim);
  }

  void _toggleOption(int groupIndex, DropGroup group, DropOption option) {
    if (!option.canChoose) return;
    final key = _groupKey(groupIndex, group);
    setState(() {
      _errorMessage = null;
      if (_selectedByGroup[key] == option.itemId) {
        _selectedByGroup.remove(key);
      } else {
        _selectedByGroup[key] = option.itemId;
      }
    });
  }

  Future<void> _confirmSelection(DropClaim claim) async {
    final itemIds = _selectedByGroup.values.toList();
    if (itemIds.isEmpty) {
      setState(() => _errorMessage = 'Choose at least one item.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm final choices?'),
        content:
            const Text('Once you confirm, these choices cannot be changed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(dropRepositoryProvider)
          .selectItems(widget.entitlementId, itemIds);
      _selectedByGroup.clear();
      ref.invalidate(dropClaimProvider(widget.entitlementId));
      ref.invalidate(myDropsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your drop choices are confirmed.')),
        );
      }
    } catch (error) {
      setState(() => _errorMessage = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SelectionBody extends StatelessWidget {
  const _SelectionBody({
    required this.claim,
    required this.selectedByGroup,
    required this.submitting,
    required this.onToggle,
    required this.onConfirm,
    this.errorMessage,
  });

  final DropClaim claim;
  final Map<String, int> selectedByGroup;
  final bool submitting;
  final String? errorMessage;
  final void Function(int groupIndex, DropGroup group, DropOption option)
      onToggle;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final groups = claim.groups.isEmpty
        ? [
            DropGroup(
                name: 'Available Items', position: 0, options: claim.items)
          ]
        : claim.groups;
    final selectedCount = selectedByGroup.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClaimHeader(claim: claim),
        const SizedBox(height: 12),
        PkCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: AppColors.pkmnYellowDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Choose up to one item from each group. Your confirmation is final.',
                  style: AppTextStyles.body(size: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < groups.length; index += 1) ...[
          _ChoiceGroupCard(
            groupIndex: index,
            group: groups[index],
            selectedItemId: selectedByGroup[_groupKey(index, groups[index])],
            onToggle: onToggle,
          ),
          const SizedBox(height: 12),
        ],
        if (errorMessage != null) ...[
          Text(errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.pkmnRed)),
          const SizedBox(height: 10),
        ],
        PkButton(
          label: selectedCount == 0
              ? 'Choose at least one item'
              : 'Confirm Final Choices',
          icon: const Icon(Icons.lock_outline),
          loading: submitting,
          expand: true,
          variant: PkButtonVariant.destructive,
          onPressed: selectedCount == 0 || submitting ? null : onConfirm,
        ),
      ],
    );
  }
}

class _ChoiceGroupCard extends StatelessWidget {
  const _ChoiceGroupCard({
    required this.groupIndex,
    required this.group,
    required this.onToggle,
    this.selectedItemId,
  });

  final int groupIndex;
  final DropGroup group;
  final int? selectedItemId;
  final void Function(int groupIndex, DropGroup group, DropOption option)
      onToggle;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.name, style: AppTextStyles.heading(size: 18)),
              ),
              Text('Optional',
                  style: AppTextStyles.label(color: AppColors.pkmnGrayDark)),
            ],
          ),
          const SizedBox(height: 12),
          for (final option in group.options) ...[
            _ChoiceOptionTile(
              option: option,
              selected: selectedItemId == option.itemId,
              onTap: () => onToggle(groupIndex, group, option),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ChoiceOptionTile extends StatelessWidget {
  const _ChoiceOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final DropOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !option.canChoose;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: AppDecorations.controlRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.pkmnGrayLight
              : selected
                  ? AppColors.pkmnBlueLight
                  : Colors.white,
          borderRadius: AppDecorations.controlRadius,
          border: Border.all(
            color: selected ? AppColors.pkmnBlue : AppColors.pkmnBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 68,
                child: PkNetworkImage(
                  imageUrl: option.imageUrl,
                  semanticLabel: option.title,
                  padding: const EdgeInsets.all(6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _OptionText(option: option)),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: disabled
                    ? AppColors.pkmnDisabled
                    : selected
                        ? AppColors.pkmnBlue
                        : AppColors.pkmnGrayDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockedBody extends StatelessWidget {
  const _UnlockedBody({required this.claim});

  final DropClaim claim;

  @override
  Widget build(BuildContext context) {
    final options = claim.unlockedOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClaimHeader(claim: claim),
        const SizedBox(height: 12),
        PkCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_open_outlined, color: AppColors.pkmnBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  claim.requiresSelection
                      ? 'Your confirmed selections are unlocked for checkout.'
                      : 'Your drop items are unlocked for checkout.',
                  style: AppTextStyles.body(size: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (options.isEmpty)
          _StateCard(
            icon: Icons.inventory_2_outlined,
            title: 'No Items Available',
            message: 'There are no active items in this drop.',
            actionLabel: 'Back Home',
            onAction: () => context.go('/'),
          )
        else
          for (final option in options) ...[
            _UnlockedOptionCard(claim: claim, option: option),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _UnlockedOptionCard extends StatelessWidget {
  const _UnlockedOptionCard({required this.claim, required this.option});

  final DropClaim claim;
  final DropOption option;

  @override
  Widget build(BuildContext context) {
    final product = option.toProductItem(claim.id);
    return PkCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 82,
                child: PkNetworkImage(
                  imageUrl: option.imageUrl,
                  semanticLabel: option.title,
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _OptionText(option: option)),
            ],
          ),
          const SizedBox(height: 12),
          if (option.isPurchased)
            Text('Already purchased',
                style: AppTextStyles.label(color: AppColors.pkmnBlue))
          else if (!option.canChoose)
            Text(option.isSoldOut ? 'Sold out' : 'Unavailable',
                style: AppTextStyles.label(color: AppColors.pkmnRed))
          else ...[
            CartQuantityControl(item: product),
            const SizedBox(height: 8),
            PkButton(
              label: 'View Item',
              icon: const Icon(Icons.open_in_new_outlined),
              variant: PkButtonVariant.secondary,
              expand: true,
              onPressed: () => context.push(option.productPath(claim.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimHeader extends StatelessWidget {
  const _ClaimHeader({required this.claim});

  final DropClaim claim;

  @override
  Widget build(BuildContext context) {
    final expiry = claim.expiresAt == null
        ? ''
        : DateFormat('MMM d, h:mm a').format(claim.expiresAt!.toLocal());
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(claim.campaignName, style: AppTextStyles.heading(size: 24)),
          if (expiry.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 18, color: AppColors.pkmnGrayDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Access expires $expiry',
                      style: AppTextStyles.body(size: 13)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionText extends StatelessWidget {
  const _OptionText({required this.option});

  final DropOption option;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(option.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading(size: 14)),
        const SizedBox(height: 4),
        Text(
            option.price <= 0
                ? 'FREE'
                : '${formatMoney(option.taxDisplay?.preTaxSubtotal ?? TaxDisplay.split(option.price).preTaxSubtotal)} + tax',
            style:
                AppTextStyles.heading(size: 14, color: AppColors.pkmnBlueDark)),
        if (option.perWinnerLimit != null) ...[
          const SizedBox(height: 3),
          Text('Limit ${option.perWinnerLimit} per winner',
              style: AppTextStyles.body(size: 12)),
        ],
        if (!option.canChoose) ...[
          const SizedBox(height: 3),
          Text(
              option.isPurchased
                  ? 'Purchased'
                  : option.isSoldOut
                      ? 'Sold out'
                      : 'Unavailable',
              style: AppTextStyles.label(color: AppColors.pkmnRed)),
        ],
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.pkmnBlue),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.heading(size: 21)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.body()),
          const SizedBox(height: 16),
          PkButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}

class _DropError extends StatelessWidget {
  const _DropError({required this.message, required this.onRefresh});

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 180),
          const Icon(Icons.error_outline, size: 48, color: AppColors.pkmnRed),
          const SizedBox(height: 12),
          Text('Drop could not be loaded',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _groupKey(int index, DropGroup group) =>
    group.id == null ? 'group-$index' : 'group-${group.id}';
