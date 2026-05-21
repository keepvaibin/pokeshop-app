import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

final _unsafeUrlPattern = RegExp(r'[\x00-\x1f\x7f\\]');

Uri? safeCampaignUri(String? rawUrl) {
  final trimmed = rawUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (_unsafeUrlPattern.hasMatch(trimmed)) return null;

  if (trimmed.startsWith('/') && !trimmed.startsWith('//')) {
    return Uri.tryParse(trimmed);
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

Future<void> openCampaignUri(BuildContext context, String? rawUrl) async {
  final uri = safeCampaignUri(rawUrl);
  if (uri == null) return;

  final localRoute = _localRouteFor(uri);
  if (localRoute != null) {
    context.go(localRoute);
    return;
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this link.')),
    );
  }
}

String? _localRouteFor(Uri uri) {
  final isRelative = !uri.hasScheme;
  final isSctcgHost = (uri.scheme == 'https' || uri.scheme == 'http') &&
      (uri.host == 'santacruztcg.com' || uri.host == 'www.santacruztcg.com');
  if (!isRelative && !isSctcgHost) return null;

  final path = uri.path.isEmpty ? '/' : uri.path;
  if (!_isKnownNativePath(path)) return null;

  return Uri(
    path: path,
    query: uri.query.isEmpty ? null : uri.query,
    fragment: uri.fragment.isEmpty ? null : uri.fragment,
  ).toString();
}

bool _isKnownNativePath(String path) {
  if (path == '/' ||
      path == '/shop' ||
      path == '/products' ||
      path == '/new-releases' ||
      path == '/search' ||
      path == '/delivery-info' ||
      path == '/cart' ||
      path == '/checkout' ||
      path == '/orders' ||
      path == '/trade-in' ||
      path == '/settings' ||
      path == '/my-sctcg') {
    return true;
  }

  return path.startsWith('/product/') ||
      path.startsWith('/category/') ||
      path.startsWith('/campaigns/') ||
      path.startsWith('/tcg/');
}
