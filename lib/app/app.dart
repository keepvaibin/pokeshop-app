import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'update_gate.dart';

class PokeshopApp extends ConsumerStatefulWidget {
  const PokeshopApp({super.key});

  @override
  ConsumerState<PokeshopApp> createState() => _PokeshopAppState();
}

class _PokeshopAppState extends ConsumerState<PokeshopApp> {
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  Future<void> _initNotifications() async {
    // Tapped while app was terminated — navigate once router is ready.
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null && mounted) _navigateFromMessage(initial);
    } catch (_) {}

    // Tapped while app was in background — foreground it and navigate.
    _messageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (mounted) _navigateFromMessage(message);
    });
  }

  void _navigateFromMessage(RemoteMessage message) {
    final url = message.data['url'];
    if (url == null || (url as String).isEmpty) return;
    ref.read(appRouterProvider).go(url);
  }

  @override
  void dispose() {
    _messageOpenedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SCTCG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) =>
          UpdateGate(child: child ?? const SizedBox()),
    );
  }
}
