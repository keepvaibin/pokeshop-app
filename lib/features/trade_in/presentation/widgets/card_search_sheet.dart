import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../data/trade_in_repository.dart';

/// Modal bottom sheet that searches the TCG card database (or loads the
/// wanted-cards list when [wantedMode] is true).  Returns the selected
/// [TradeCardEntry] via [Navigator.pop].
class CardSearchSheet extends StatefulWidget {
  const CardSearchSheet({
    required this.repository,
    this.wantedMode = false,
    super.key,
  });

  final TradeInRepository repository;
  final bool wantedMode;

  @override
  State<CardSearchSheet> createState() => _CardSearchSheetState();
}

class _CardSearchSheetState extends State<CardSearchSheet> {
  final _controller = TextEditingController();
  List<TradeCardSearchResult> _results = const [];
  bool _loading = false;
  String? _hint;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.wantedMode) _loadWanted();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadWanted() async {
    setState(() {
      _loading = true;
      _hint = null;
    });
    try {
      final results = await widget.repository.wantedCards();
      if (mounted) {
        setState(() {
          _results = results;
          if (results.isEmpty) _hint = 'No wanted cards on file.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hint = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = const [];
        _hint = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _hint = null;
    });
    try {
      final results = await widget.repository.searchCards(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _hint = results.isEmpty ? 'No cards found for "$query".' : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hint = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(TradeCardSearchResult card) =>
      Navigator.of(context).pop(card.toEntry());

  @override
  Widget build(BuildContext context) {
    final title =
        widget.wantedMode ? 'Favorites / Wanted Cards' : 'Search Card Database';
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.pkmnGrayMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: AppTextStyles.heading(size: 18)),
          ),
          const SizedBox(height: 12),
          if (!widget.wantedMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  if (v.trim().length >= 2) _search(v);
                },
                decoration: InputDecoration(
                  hintText: 'Search TCG card database…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  _results = const [];
                                  _hint = null;
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading && _results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _hint != null && _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _hint!,
                            style: AppTextStyles.body(
                                color: AppColors.pkmnGrayDark),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _results.isEmpty && !widget.wantedMode
                        ? Center(
                            child: Text(
                              'Type at least 2 characters to search.',
                              style: AppTextStyles.body(
                                  color: AppColors.pkmnGrayDark),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                    horizontal: 16)
                                .copyWith(bottom: 24),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => CardResultTile(
                              card: _results[i],
                              onTap: () => _select(_results[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// A single search result row used inside [CardSearchSheet].
class CardResultTile extends StatelessWidget {
  const CardResultTile({
    required this.card,
    required this.onTap,
    super.key,
  });

  final TradeCardSearchResult card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.pkmnBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 64,
                child: PkNetworkImage(
                  imageUrl: card.imageUrl.isEmpty ? null : card.imageUrl,
                  semanticLabel: card.name,
                  padding: const EdgeInsets.all(2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.name,
                            style: AppTextStyles.heading(size: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (card.marketPrice > 0)
                          Text(
                            '\$${card.marketPrice.toStringAsFixed(2)}',
                            style: AppTextStyles.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                      ],
                    ),
                    if (card.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(size: 11),
                      ),
                    ],
                    if (card.tcgSubType.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.tcgSubType,
                        style: AppTextStyles.body(
                            size: 11, color: AppColors.pkmnGrayDark),
                        maxLines: 1,
                      ),
                    ],
                    if (card.marketPrice <= 0)
                      Text(
                        'Price unavailable',
                        style: AppTextStyles.body(
                            size: 11, color: AppColors.pkmnGrayDark),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.add_circle,
                  color: AppColors.pkmnBlue, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
