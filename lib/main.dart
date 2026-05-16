import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/theme/app_colors.dart';

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
  } catch (_) {
    // Firebase platform files are added by `flutterfire configure` per environment.
  }

  runApp(const ProviderScope(child: PokeshopApp()));
}
