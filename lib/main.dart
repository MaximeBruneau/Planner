import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'views/calendar/calendar_screen.dart';
import 'views/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init in main: $e');
  }

  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const SuperPlannerApp(),
    ),
  );
}

class SuperPlannerApp extends ConsumerWidget {
  const SuperPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final themeData = AppTheme.getThemeById(settings.themeId);

    return MaterialApp(
      title: 'Super Planner 🗓️',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: authState.isSignedIn
          ? const CalendarScreen()
          : const AuthScreen(),
    );
  }
}
