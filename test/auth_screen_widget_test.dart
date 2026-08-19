import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_dairy/views/auth/auth_screen.dart';
import 'package:my_dairy/core/services/storage_service.dart';
import 'package:my_dairy/providers/mood_provider.dart';

void main() {
  Widget createAuthScreen(StorageService storageService) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const MaterialApp(
        home: AuthScreen(),
      ),
    );
  }

  group('AuthScreen UI Widget Tests', () {
    testWidgets('Renders all initial branding, Google button and Sign In form',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(createAuthScreen(storageService));
      await tester.pumpAndSettle();

      expect(find.text('DuoVibe 🌸'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In ✨'), findsOneWidget);
    });

    testWidgets('Toggling between Sign In and Create Account updates form fields',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(createAuthScreen(storageService));
      await tester.pumpAndSettle();

      // In Sign In mode, Name field is absent
      expect(find.text('Your Name / Nickname'), findsNothing);
      expect(find.text('Forgot password?'), findsOneWidget);

      // Switch to Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // In Create Account mode, Name field appears, Forgot password disappears
      expect(find.text('Your Name / Nickname'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);
      expect(find.text('Create My Account 🌸'), findsOneWidget);

      // Switch back to Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Your Name / Nickname'), findsNothing);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('Form validation rejects empty email and short passwords',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(createAuthScreen(storageService));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Sign In ✨');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Forgot password button opens modal dialog',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      await storageService.init();

      await tester.pumpWidget(createAuthScreen(storageService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password 🔑'), findsOneWidget);
      expect(find.text('Send Link'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password 🔑'), findsNothing);
    });
  });
}
