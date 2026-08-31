import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_user.dart';
import '../../models/shared_space.dart';
import '../../models/plan_activity.dart';
import '../../models/activity_notification.dart';
import '../../models/bank_idea.dart';
import '../../models/day_unavailability.dart';
import '../../models/app_settings.dart';

class StorageService {
  static const String _userKey = 'super_planner_user_v1';
  static const String _spaceKey = 'super_planner_current_space_v1';
  static const String _activitiesPrefix = 'super_planner_activities_';
  static const String _notificationsPrefix = 'super_planner_notifications_';
  static const String _readNotifsPrefix = 'super_planner_read_notifs_';
  static const String _ideasPrefix = 'super_planner_ideas_';
  static const String _unavailabilitiesPrefix = 'super_planner_unavailabilities_';
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

  // --- Space Activity Notifications ---
  List<ActivityNotification> getSpaceNotifications(String spaceId) {
    if (spaceId.isEmpty) return [];
    try {
      final jsonString = _prefs.getString('$_notificationsPrefix$spaceId');
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> rawList = jsonDecode(jsonString);
      return rawList
          .map((item) => ActivityNotification.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error reading space notifications: $e');
      return [];
    }
  }

  Future<void> saveSpaceNotifications(String spaceId, List<ActivityNotification> notifications) async {
    if (spaceId.isEmpty) return;
    try {
      // Keep up to 100 most recent notifications
      final trimmed = notifications.length > 100 ? notifications.sublist(0, 100) : notifications;
      final rawList = trimmed.map((a) => a.toMap()).toList();
      await _prefs.setString('$_notificationsPrefix$spaceId', jsonEncode(rawList));
    } catch (e) {
      debugPrint('Error saving space notifications: $e');
    }
  }

  Set<String> getReadNotificationIds(String spaceId) {
    if (spaceId.isEmpty) return {};
    try {
      final list = _prefs.getStringList('$_readNotifsPrefix$spaceId');
      return list?.toSet() ?? {};
    } catch (e) {
      debugPrint('Error reading read notification IDs: $e');
      return {};
    }
  }

  Future<void> markNotificationIdsAsRead(String spaceId, Iterable<String> ids) async {
    if (spaceId.isEmpty || ids.isEmpty) return;
    try {
      final current = getReadNotificationIds(spaceId);
      current.addAll(ids);
      final trimmed = current.length > 200
          ? current.toList().sublist(current.length - 200)
          : current.toList();
      await _prefs.setStringList('$_readNotifsPrefix$spaceId', trimmed);
    } catch (e) {
      debugPrint('Error saving read notification IDs: $e');
    }
  }

  // --- Space Ideas (Idea Bank) ---
  List<BankIdea> getSpaceIdeas(String spaceId) {
    if (spaceId.isEmpty) return [];
    try {
      final jsonString = _prefs.getString('$_ideasPrefix$spaceId');
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> rawList = jsonDecode(jsonString);
      return rawList
          .map((item) => BankIdea.fromMap(item as Map<String, dynamic>))
          .where((i) => !i.deleted)
          .toList();
    } catch (e) {
      debugPrint('Error reading space ideas: $e');
      return [];
    }
  }

  Future<void> saveSpaceIdeas(String spaceId, List<BankIdea> ideas) async {
    if (spaceId.isEmpty) return;
    try {
      final rawList = ideas.map((i) => i.toMap()).toList();
      await _prefs.setString('$_ideasPrefix$spaceId', jsonEncode(rawList));
    } catch (e) {
      debugPrint('Error saving space ideas: $e');
    }
  }

  // --- Space Member Unavailabilities ---
  List<DayUnavailability> getSpaceUnavailabilities(String spaceId) {
    if (spaceId.isEmpty) return [];
    try {
      final jsonString = _prefs.getString('$_unavailabilitiesPrefix$spaceId');
      if (jsonString == null || jsonString.isEmpty) return [];
      final List<dynamic> rawList = jsonDecode(jsonString);
      return rawList
          .map((item) => DayUnavailability.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error reading space unavailabilities: $e');
      return [];
    }
  }

  Future<void> saveSpaceUnavailabilities(String spaceId, List<DayUnavailability> unavailabilities) async {
    if (spaceId.isEmpty) return;
    try {
      final rawList = unavailabilities.map((u) => u.toMap()).toList();
      await _prefs.setString('$_unavailabilitiesPrefix$spaceId', jsonEncode(rawList));
    } catch (e) {
      debugPrint('Error saving space unavailabilities: $e');
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
