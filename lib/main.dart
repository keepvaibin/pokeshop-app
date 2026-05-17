import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/theme/app_colors.dart';

/// Top-level handler required by FCM for messages received when the app is
/// terminated. Must be a top-level function annotated with vm:entry-point.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification messages are shown automatically by the system.
  // Nothing extra needed here unless processing data-only messages.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.pkmnBg,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.pkmnBg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Firebase platform files are added by `flutterfire configure` per environment.
  }

  runApp(const ProviderScope(child: PokeshopApp()));
}
