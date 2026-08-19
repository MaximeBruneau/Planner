import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_dairy/models/app_user.dart';
import 'package:my_dairy/models/mood_entry.dart';
import 'package:my_dairy/providers/auth_provider.dart';
import 'package:my_dairy/core/services/storage_service.dart';

void main() {
  group('1. AuthState Model & Transitions Tests', () {
    test('Initial AuthState is not signed in and has no errors', () {
      const state = AuthState();
      expect(state.isSignedIn, isFalse);
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('AuthState with AppUser returns isSignedIn == true', () {
      final user = AppUser(
        id: 'user_123',
        email: 'camille@example.com',
        displayName: 'Camille 🌸',
      );
      final state = const AuthState().copyWith(user: user);
      expect(state.isSignedIn, isTrue);
      expect(state.user?.email, equals('camille@example.com'));
      expect(state.user?.displayName, equals('Camille 🌸'));
    });

    test('AuthState copyWith preserves and updates fields correctly', () {
      final user = AppUser(
        id: 'user_123',
        email: 'camille@example.com',
        displayName: 'Camille 🌸',
      );
      final loadingState = const AuthState().copyWith(isLoading: true);
      expect(loadingState.isLoading, isTrue);

      final errorState = loadingState.copyWith(
        isLoading: false,
        errorMessage: 'Invalid credentials',
      );
      expect(errorState.isLoading, isFalse);
      expect(errorState.errorMessage, equals('Invalid credentials'));

      final loggedInState = errorState.copyWith(
        user: user,
        errorMessage: null,
      );
      expect(loggedInState.isSignedIn, isTrue);
      expect(loggedInState.errorMessage, isNull);
    });
  });

  group('2. Automatic Continuous Sync & Local Persistence Tests', () {
    test('StorageService persists and restores user session across app restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      expect(storage.getSavedUser(), isNull);

      final user = AppUser(
        id: 'user_abc',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      await storage.saveUser(user);
      final restoredUser = storage.getSavedUser();

      expect(restoredUser, isNotNull);
      expect(restoredUser?.id, equals('user_abc'));
      expect(restoredUser?.email, equals('test@example.com'));
      expect(restoredUser?.displayName, equals('Test User'));

      // Sign out clears persisted user
      await storage.saveUser(null);
      expect(storage.getSavedUser(), isNull);
    });

    test('Immediate MoodEntry creation saves locally with synced flag and preserved timestamp', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      final updateTime = DateTime(2026, 8, 19, 14, 0);
      final entry = MoodEntry(
        date: '2026-08-19',
        emoji: '🌸',
        note: 'Excited for today!',
        updatedAt: updateTime,
        syncStatus: 'synced',
      );

      await storage.saveEntry(entry);
      final allEntries = storage.getAllEntries();
      final savedEntry = allEntries['2026-08-19'];

      expect(savedEntry, isNotNull);
      expect(savedEntry?.emoji, equals('🌸'));
      expect(savedEntry?.note, equals('Excited for today!'));
      expect(savedEntry?.updatedAt.hour, equals(14));
      expect(savedEntry?.syncStatus, equals('synced'));
    });
  });
}
