import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_user.dart';
import '../../models/shared_space.dart';
import '../../models/plan_activity.dart';
import '../../models/app_settings.dart';

class StorageService {
  static const String _userKey = 'super_planner_user_v1';
  static const String _spaceKey = 'super_planner_current_space_v1';
  static const String _activitiesPrefix = 'super_planner_activities_';
  static const String _settingsKey = 'super_planner_settings_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- App User ---
  AppUser? getSavedUser() {
    try {
      final jsonString = _prefs.getString(_userKey);
      if (jsonString == null || jsonString.isEmpty) return null;
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

  // --- Shared Space ---
  SharedSpace? getCurrentSpace() {
    try {
      final jsonString = _prefs.getString(_spaceKey);
      if (jsonString == null || jsonString.isEmpty) return null;
      return SharedSpace.fromJson(jsonString);
    } catch (e) {
      debugPrint('Error reading current space: $e');
      return null;
    }
  }

  Future<void> saveCurrentSpace(SharedSpace? space) async {
    if (space == null) {
      await _prefs.remove(_spaceKey);
    } else {
      await _prefs.setString(_spaceKey, space.toJson());
    }
  }

  // --- Space Activities ---
  List<PlanActivity> getSpaceActivities(String spaceId) {
    if (spaceId.isEmpty) return [];
    try {
      final jsonString = _prefs.getString('$_activitiesPrefix$spaceId');
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> rawList = jsonDecode(jsonString);
      return rawList
          .map((item) => PlanActivity.fromMap(item as Map<String, dynamic>))
          .where((a) => !a.deleted)
          .toList();
    } catch (e) {
      debugPrint('Error reading space activities: $e');
      return [];
    }
  }

  Future<void> saveSpaceActivities(String spaceId, List<PlanActivity> activities) async {
    if (spaceId.isEmpty) return;
    try {
      final rawList = activities.map((a) => a.toMap()).toList();
      await _prefs.setString('$_activitiesPrefix$spaceId', jsonEncode(rawList));
    } catch (e) {
      debugPrint('Error saving space activities: $e');
    }
  }

  // --- App Settings ---
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

  // --- Clear All Data ---
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be initialized in main');
});
