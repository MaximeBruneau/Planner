import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/mood_entry.dart';
import '../../models/app_settings.dart';

class StorageService {
  static const String _entriesKey = 'vibe_mood_entries_v1';
  static const String _settingsKey = 'vibe_app_settings_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Mood Entries CRUD
  Map<String, MoodEntry> getAllEntries() {
    try {
      final jsonString = _prefs.getString(_entriesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      final Map<String, dynamic> rawMap = jsonDecode(jsonString);
      final Map<String, MoodEntry> entries = {};
      rawMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          entries[key] = MoodEntry.fromMap(value);
        } else if (value is String) {
          entries[key] = MoodEntry.fromJson(value);
        }
      });
      return entries;
    } catch (e) {
      debugPrint('Error reading mood entries: $e');
      return {};
    }
  }

  MoodEntry? getEntryForDate(String dateStr) {
    final entries = getAllEntries();
    return entries[dateStr];
  }

  Future<void> saveEntry(MoodEntry entry) async {
    final entries = getAllEntries();
    entries[entry.date] = entry;

    final rawMap = entries.map((key, value) => MapEntry(key, value.toMap()));
    await _prefs.setString(_entriesKey, jsonEncode(rawMap));
  }

  Future<void> deleteEntry(String dateStr) async {
    final entries = getAllEntries();
    if (entries.containsKey(dateStr)) {
      entries.remove(dateStr);
      final rawMap = entries.map((key, value) => MapEntry(key, value.toMap()));
      await _prefs.setString(_entriesKey, jsonEncode(rawMap));
    }
  }

  Future<void> saveAllEntries(Map<String, MoodEntry> newEntries) async {
    final rawMap = newEntries.map((key, value) => MapEntry(key, value.toMap()));
    await _prefs.setString(_entriesKey, jsonEncode(rawMap));
  }

  // App Settings Persistence
  AppSettings getSettings() {
    try {
      final jsonString = _prefs.getString(_settingsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return AppSettings();
      }
      return AppSettings.fromJson(jsonString);
    } catch (e) {
      debugPrint('Error reading settings: $e');
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, settings.toJson());
  }
}
