import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_dairy/main.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:my_dairy/core/utils/date_utils_helper.dart';
import 'package:my_dairy/models/app_user.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/providers/mood_provider.dart';

void main() {
  testWidgets('App renders AuthScreen by default when not signed in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const VibeCalendarApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AuthScreen branding and sign-in buttons
    expect(find.text('DuoVibe 🌸'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('App renders main calendar screen when signed in',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    // Pre-save user session
    await storageService.saveUser(
      AppUser(
        id: 'test_user_1',
        email: 'user@example.com',
        displayName: 'Alex 🌸',
      ),
    );

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

  testWidgets('Switching to Duo Vibe displays Partner Pairing card when unpaired',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    // Pre-save user session
    await storageService.saveUser(
      AppUser(
        id: 'test_user_1',
        email: 'user@example.com',
        displayName: 'Alex 🌸',
      ),
    );

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

    // Header updates to Duo Vibe
    expect(find.text('Duo Vibe '), findsOneWidget);
    // Partner pairing card appears
    expect(find.text('Share with your Partner 🐰'), findsOneWidget);
  });
}
