import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/shop/data/shop_repository.dart';

/// Wraps the entire app and shows an unskippable "Update Required" dialog
/// when the installed version is below [StoreSettings.minimumAppVersion].
///
/// Set `minimum_app_version` to `"0.0.0"` (the default) in admin settings to
/// disable the gate entirely.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _dialogShown = false;

  // Play Store URL — update once the app is published.
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.santacruztcg.pokeshop_app';

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(storeSettingsProvider);

    settingsAsync.whenData((settings) {
      final minimum = settings.minimumAppVersion;
      if (_dialogShown || minimum.isEmpty || minimum == '0.0.0') return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_dialogShown || !mounted) return;
        final ctx = context; // capture before async gap
        try {
          final info = await PackageInfo.fromPlatform();
          if (!ctx.mounted || _dialogShown) return;
          if (!_isVersionSufficient(info.version, minimum)) {
            _dialogShown = true;
            _showUpdateDialog(ctx);
          }
        } catch (_) {
          // If we can't read the package version, fail open.
        }
      });
    });

    return widget.child;
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Update Required'),
          content: const Text(
            'A new version of the SCTCG app is available.\n\n'
            'Please update to continue using the app.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(_playStoreUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns true if [current] >= [minimum].
  /// Both are expected to be in "major.minor.patch" format.
  static bool _isVersionSufficient(String current, String minimum) {
    final c = _parseParts(current);
    final m = _parseParts(minimum);
    final len = m.length > c.length ? m.length : c.length;
    for (int i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv < mv) return false;
      if (cv > mv) return true;
    }
    return true; // equal
  }

  static List<int> _parseParts(String version) {
    return version
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }
}
