/// Centralized application constants for Super Planner.
///
/// All magic numbers, durations, limits, and storage keys are defined here
/// to ensure consistency and easy maintenance across the codebase.
library;

/// Storage keys used with SharedPreferences.
abstract final class StorageKeys {
  static const String user = 'super_planner_user_v1';
  static const String currentSpace = 'super_planner_current_space_v1';
  static const String activitiesPrefix = 'super_planner_activities_';
  static const String notificationsPrefix = 'super_planner_notifications_';
  static const String ideasPrefix = 'super_planner_ideas_';
  static const String settings = 'super_planner_settings_v1';
}

/// Duration constants used across the app.
abstract final class AppDurations {
  /// Auto-dismiss duration for in-app notice banners.
  static const Duration noticeBannerAutoDismiss = Duration(seconds: 2);

  /// Firestore operation timeout.
  static const Duration firestoreTimeout = Duration(seconds: 6);

  /// Maximum age for a notification to be considered "live" (real-time).
  static const Duration liveNotificationWindow = Duration(seconds: 60);

  /// Debounce delay for search input.
  static const Duration searchDebounce = Duration(milliseconds: 300);
}

/// Numeric limits and thresholds.
abstract final class AppLimits {
  /// Maximum number of notifications stored locally per space.
  static const int maxStoredNotifications = 100;

  /// Maximum size of the seen-change-IDs cache before cleanup.
  static const int seenChangeCacheLimit = 500;

  /// Length of the generated space invite code.
  static const int inviteCodeLength = 6;
}

/// Firestore collection and field names.
abstract final class FirestoreCollections {
  static const String spaces = 'spaces';
  static const String activities = 'activities';
  static const String notifications = 'notifications';
  static const String ideas = 'ideas';
  static const String users = 'users';
}
