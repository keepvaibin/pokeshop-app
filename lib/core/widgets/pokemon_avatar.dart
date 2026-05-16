import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

String? pokemonIconUrl(String? filename) {
  final value = filename?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  return 'assets/pkmn_icons/$value';
}

class PokemonAvatar extends StatelessWidget {
  const PokemonAvatar({
    required this.filename,
    required this.fallbackText,
    this.size = 64,
    super.key,
  });

  final String? filename;
  final String fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final source = pokemonIconUrl(filename);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pkmnBlueLight,
        border: Border.all(color: AppColors.pkmnBlue, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: source == null
          ? Center(
              child: Text(
                _initials(fallbackText),
                style: TextStyle(
                  color: AppColors.pkmnBlueDark,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.28,
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: source.startsWith('http')
                  ? Image.network(
                      source,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _initials(fallbackText),
                          style: TextStyle(
                            color: AppColors.pkmnBlueDark,
                            fontWeight: FontWeight.w800,
                            fontSize: size * 0.28,
                          ),
                        ),
                      ),
                    )
                  : Image.asset(
                      source,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _initials(fallbackText),
                          style: TextStyle(
                            color: AppColors.pkmnBlueDark,
                            fontWeight: FontWeight.w800,
                            fontSize: size * 0.28,
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'S';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }
}
