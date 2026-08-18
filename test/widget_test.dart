import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_dairy/main.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:my_dairy/core/utils/date_utils_helper.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/providers/mood_provider.dart';

void main() {
  testWidgets('App renders main calendar screen with title and streak chip',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    // Pre-save today's entry to prevent auto-prompt modal
    final todayStr = DateUtilsHelper.formatYmd(DateTime.now());
    await storageService.saveEntry(MoodEntry(date: todayStr, emoji: '🌸'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const VibeCalendarApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main screen renders title "My Vibe "
    expect(find.text('My Vibe '), findsOneWidget);
    // Verify streak pill is displayed
    expect(find.text('1 streak'), findsOneWidget);
  });

  testWidgets('Switching to FT Vibe displays Partner Pairing card when unpaired',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    // Pre-save today's entry to prevent auto-prompt modal
    final todayStr = DateUtilsHelper.formatYmd(DateTime.now());
    await storageService.saveEntry(MoodEntry(date: todayStr, emoji: '🌸'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const VibeCalendarApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap switch tab button (icon: Icons.swap_horiz_rounded)
    final switchBtn = find.byIcon(Icons.swap_horiz_rounded);
    expect(switchBtn, findsOneWidget);
    await tester.tap(switchBtn);
    await tester.pumpAndSettle();

    // Header updates to FT Vibe
    expect(find.text('FT Vibe '), findsOneWidget);
    // Partner pairing card appears
    expect(find.text('Share with your FT 🐰'), findsOneWidget);
  });
}
