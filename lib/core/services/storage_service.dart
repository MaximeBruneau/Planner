import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/mood_entry.dart';
import '../../models/app_settings.dart';
import '../../models/app_user.dart';
import '../../models/partner_info.dart';

class StorageService {
  static const String _entriesKey = 'vibe_mood_entries_v2';
  static const String _settingsKey = 'vibe_app_settings_v2';
  static const String _userKey = 'vibe_app_user_v2';
  static const String _partnerKey = 'vibe_partner_info_v2';
  static const String _partnerEntriesKey = 'vibe_partner_entries_v2';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User Profile Persistence
  AppUser? getSavedUser() {
    try {
      final jsonString = _prefs.getString(_userKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return AppUser.fromJson(jsonString);
    } catch (e) {
      debugPrint('Error reading saved user: $e');
      return null;
    }
  }

  Future<void> saveUser(AppUser? user) async {
    if (user == null) {
      await _prefs.remove(_userKey);
    } else {
      await _prefs.setString(_userKey, user.toJson());
    }
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
    final entry = entries[dateStr];
    if (entry != null && entry.deleted) return null;
    return entry;
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
      final existing = entries[dateStr]!;
      // Mark as deleted tombstone with pending sync
      entries[dateStr] = existing.copyWith(
        deleted: true,
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );
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

  // Partner Info & Entries Cache
  PartnerInfo? getSavedPartner() {
    try {
      final jsonString = _prefs.getString(_partnerKey);
      if (jsonString == null || jsonString.isEmpty) return null;
      return PartnerInfo.fromJson(jsonString);
    } catch (e) {
      debugPrint('Error reading partner info: $e');
      return null;
    }
  }

  Future<void> savePartner(PartnerInfo? partner) async {
    if (partner == null) {
      await _prefs.remove(_partnerKey);
      await _prefs.remove(_partnerEntriesKey);
    } else {
      await _prefs.setString(_partnerKey, partner.toJson());
    }
  }

  Map<String, MoodEntry> getPartnerEntries() {
    try {
      final jsonString = _prefs.getString(_partnerEntriesKey);
      if (jsonString == null || jsonString.isEmpty) return {};
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
      debugPrint('Error reading partner entries: $e');
      return {};
    }
  }

  Future<void> savePartnerEntries(Map<String, MoodEntry> entries) async {
    final rawMap = entries.map((key, value) => MapEntry(key, value.toMap()));
    await _prefs.setString(_partnerEntriesKey, jsonEncode(rawMap));
  }
}
