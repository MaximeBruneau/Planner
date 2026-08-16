import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/mood_provider.dart';
import 'providers/settings_provider.dart';
import 'views/calendar/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const VibeCalendarApp(),
    ),
  );
}

class VibeCalendarApp extends ConsumerWidget {
  const VibeCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeData = AppTheme.getTheme(settings.themeIndex);

    return MaterialApp(
      title: 'My Vibe 🌸',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const CalendarScreen(),
    );
  }
}
