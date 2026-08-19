import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../core/services/storage_service.dart';
import '../core/services/auth_sync_service.dart';
import '../core/services/notification_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main()');
});

final authSyncServiceProvider = Provider<AuthSyncService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthSyncService(storage);
});

class MoodNotifier extends StateNotifier<Map<String, MoodEntry>> {
  final StorageService _storageService;
  final AuthSyncService _authSyncService;
  final NotificationService _notificationService;

  MoodNotifier(
    this._storageService,
    this._authSyncService,
    this._notificationService,
  ) : super({}) {
    loadEntries();
  }

  void loadEntries() {
    final all = _storageService.getAllEntries();
    final nonDeleted = <String, MoodEntry>{};
    all.forEach((key, value) {
      if (!value.deleted) {
        nonDeleted[key] = value;
      }
    });
    state = nonDeleted;
    _updateNotificationSchedule();
  }

  static String formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool hasEntryForDate(DateTime date) {
    final key = formatDateKey(date);
    return state.containsKey(key) && !state[key]!.deleted;
  }

  MoodEntry? getEntryForDate(DateTime date) {
    final key = formatDateKey(date);
    final entry = state[key];
    if (entry != null && entry.deleted) return null;
    return entry;
  }

  Future<void> setEntry({
    required DateTime date,
    required String emoji,
    required String note,
  }) async {
    final dateKey = formatDateKey(date);
    final newEntry = MoodEntry(
      date: dateKey,
      emoji: emoji,
      note: note.trim(),
      updatedAt: DateTime.now(),
      deleted: false,
      syncStatus: 'synced',
    );

    // Save to Local DB
    await _storageService.saveEntry(newEntry);

    // Update state
    final updatedMap = Map<String, MoodEntry>.from(state);
    updatedMap[dateKey] = newEntry;
    state = updatedMap;

    // Backup to Cloud async
    _authSyncService.backupSingleEntry(newEntry);

    // Update daily notification check
    _updateNotificationSchedule();
  }

  Future<void> deleteEntry(DateTime date) async {
    final dateKey = formatDateKey(date);
    if (!state.containsKey(dateKey)) return;

    await _storageService.deleteEntry(dateKey);

    final updatedMap = Map<String, MoodEntry>.from(state);
    updatedMap.remove(dateKey);
    state = updatedMap;

    _authSyncService.deleteCloudEntry(dateKey);
    _updateNotificationSchedule();
  }

  void _updateNotificationSchedule() {
    final settings = _storageService.getSettings();
    if (!settings.notificationsEnabled) {

      _notificationService.cancelAll();
      return;
    }

    final parts = settings.notificationTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 21;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final todayKey = formatDateKey(DateTime.now());
    final hasLoggedToday = state.containsKey(todayKey) && !state[todayKey]!.deleted;
    _notificationService.scheduleDailyReminder(
      hasEntryToday: () => hasLoggedToday,
      hour: hour,
      minute: minute,
    );
  }

}

final moodProvider =
    StateNotifierProvider<MoodNotifier, Map<String, MoodEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final authSync = ref.watch(authSyncServiceProvider);
  return MoodNotifier(storage, authSync, NotificationService());
});
