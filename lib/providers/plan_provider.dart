import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/plan_activity.dart';
import '../../models/activity_notification.dart';
import '../../models/app_user.dart';
import '../../core/utils/date_utils_helper.dart';
import '../core/services/plan_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import 'auth_provider.dart';
import 'space_provider.dart';

class PlanState {
  final List<PlanActivity> activities;
  final List<ActivityNotification> notifications;
  final bool isLoading;
  final String? lastInAppNotice;

  const PlanState({
    this.activities = const [],
    this.notifications = const [],
    this.isLoading = false,
    this.lastInAppNotice,
  });

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  PlanState copyWith({
    List<PlanActivity>? activities,
    List<ActivityNotification>? notifications,
    bool? isLoading,
    String? lastInAppNotice,
    bool clearNotice = false,
  }) {
    return PlanState(
      activities: activities ?? this.activities,
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      lastInAppNotice: clearNotice ? null : (lastInAppNotice ?? this.lastInAppNotice),
    );
  }
}

class PlanNotifier extends StateNotifier<PlanState> {
  final PlanService _planService;
  final StorageService _storageService;
  final Ref _ref;
  StreamSubscription<List<PlanActivity>>? _activitySubscription;
  StreamSubscription<List<ActivityNotification>>? _notificationSubscription;
  Timer? _noticeAutoDismissTimer;

  PlanNotifier(this._planService, this._storageService, this._ref)
      : super(const PlanState()) {
    _init();
  }

  void _init() {
    final currentSpace = _ref.read(spaceProvider).currentSpace;
    if (currentSpace != null) {
      final cachedActivities = _storageService.getSpaceActivities(currentSpace.id);
      final cachedNotifications = _storageService.getSpaceNotifications(currentSpace.id);
      state = state.copyWith(
        activities: cachedActivities,
        notifications: cachedNotifications,
      );
      _subscribeToSpace(currentSpace.id);
    }

    _ref.listen<SpaceState>(spaceProvider, (previous, next) {
      if (next.currentSpace != null) {
        final cachedActivities = _storageService.getSpaceActivities(next.currentSpace!.id);
        final cachedNotifications = _storageService.getSpaceNotifications(next.currentSpace!.id);
        state = state.copyWith(
          activities: cachedActivities,
          notifications: cachedNotifications,
        );
        _subscribeToSpace(next.currentSpace!.id);
      } else {
        _activitySubscription?.cancel();
        _notificationSubscription?.cancel();
        state = const PlanState();
      }
    });
  }

  AppUser _getCurrentUser() {
    return _ref.read(authProvider).user ??
        _storageService.getSavedUser() ??
        AppUser(id: 'local_user', displayName: 'Planner User', email: '');
  }

  void _subscribeToSpace(String spaceId) {
    if (spaceId.isEmpty) return;
    _activitySubscription?.cancel();
    _notificationSubscription?.cancel();

    final user = _getCurrentUser();

    // Stream Activities
    _activitySubscription = _planService.streamSpaceActivities(
      spaceId: spaceId,
      currentUser: user,
      onGroupActivityNotice: (notice) {
        _displayNoticeWithAutoDismiss(notice);
      },
    ).listen((activities) {
      state = state.copyWith(activities: activities, isLoading: false);
    });

    // Stream Notifications Feed
    _notificationSubscription = _planService.streamSpaceNotifications(
      spaceId: spaceId,
      currentUser: user,
    ).listen((notifications) {
      state = state.copyWith(notifications: notifications);
    });
  }

  /// Display in-app popup notification and automatically dismiss after exactly 2 seconds
  void _displayNoticeWithAutoDismiss(String notice) {
    _noticeAutoDismissTimer?.cancel();
    state = state.copyWith(lastInAppNotice: notice);
    _noticeAutoDismissTimer = Timer(const Duration(seconds: 2), () {
      clearNotice();
    });
  }

  void clearNotice() {
    _noticeAutoDismissTimer?.cancel();
    state = state.copyWith(clearNotice: true);
  }

  void markAllNotificationsAsRead() {
    final ids = state.notifications.map((n) => n.id).toList();
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);

    final currentSpace = _ref.read(spaceProvider).currentSpace;
    if (currentSpace != null) {
      _storageService.saveSpaceNotifications(currentSpace.id, updated);
      _storageService.markNotificationIdsAsRead(currentSpace.id, ids);
    }
  }

  // --- Filtering & Date Helpers ---

  List<PlanActivity> getActivitiesForDate(DateTime date) {
    final dateStr = DateUtilsHelper.formatYmd(date);
    final list = state.activities.where((a) => a.date == dateStr && !a.deleted).toList();
    // Sort: Unchecked items first, then newer items first
    list.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  bool hasActivitiesForDate(DateTime date) {
    final dateStr = DateUtilsHelper.formatYmd(date);
    return state.activities.any((a) => a.date == dateStr && !a.deleted);
  }

  int getCountForDate(DateTime date) {
    final dateStr = DateUtilsHelper.formatYmd(date);
    return state.activities.where((a) => a.date == dateStr && !a.deleted).length;
  }

  // --- Actions with Instant Optimistic UI Update ---

  Future<void> addItem({
    required String text,
    required DateTime date,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = _getCurrentUser();
    final space = _ref.read(spaceProvider).currentSpace;
    final spaceId = space?.id ?? 'space_default';
    final dateStr = DateUtilsHelper.formatYmd(date);

    final item = PlanActivity(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: spaceId,
      date: dateStr,
      title: trimmed,
      creatorId: user.id,
      creatorName: user.displayName,
      creatorPhotoUrl: user.photoUrl,
      upvoterIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notif = ActivityNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: spaceId,
      title: '${user.displayName} added "$trimmed" for $dateStr',
      date: dateStr,
      authorName: user.displayName,
      authorPhotoUrl: user.photoUrl,
      type: NotificationType.add,
      createdAt: DateTime.now(),
      isRead: true,
    );

    // 1. Instant optimistic state update
    state = state.copyWith(
      activities: [item, ...state.activities.where((a) => a.id != item.id)],
      notifications: [notif, ...state.notifications],
    );

    // 2. Persist locally and sync to cloud
    await _planService.saveActivity(activity: item, user: user);
    await _planService.logNotification(spaceId: spaceId, notification: notif);
  }

  Future<void> toggleUpvote(PlanActivity activity) async {
    final user = _getCurrentUser();

    final upvoters = List<String>.from(activity.upvoterIds);
    final hasVoted = upvoters.contains(user.id);
    if (hasVoted) {
      upvoters.remove(user.id);
    } else {
      upvoters.add(user.id);
    }

    final updated = activity.copyWith(
      upvoterIds: upvoters,
      updatedAt: DateTime.now(),
    );

    // 1. Instant optimistic state update
    final updatedList = state.activities.map((a) {
      return a.id == activity.id ? updated : a;
    }).toList();
    state = state.copyWith(activities: updatedList);

    // 2. Persist and sync
    await _planService.saveActivity(activity: updated, user: user);

    if (!hasVoted) {
      final notif = ActivityNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        spaceId: activity.spaceId,
        title: '${user.displayName} upvoted "${activity.title}" 👍',
        date: activity.date,
        authorName: user.displayName,
        authorPhotoUrl: user.photoUrl,
        type: NotificationType.upvote,
        createdAt: DateTime.now(),
        isRead: true,
      );
      state = state.copyWith(notifications: [notif, ...state.notifications]);
      await _planService.logNotification(spaceId: activity.spaceId, notification: notif);
    }
  }

  Future<void> toggleDone(PlanActivity activity) async {
    final user = _getCurrentUser();

    final isNowDone = !activity.isDone;
    final updated = activity.copyWith(
      isDone: isNowDone,
      updatedAt: DateTime.now(),
    );

    final notif = ActivityNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: activity.spaceId,
      title: isNowDone
          ? '${user.displayName} checked off "${activity.title}" ✅'
          : '${user.displayName} unchecked "${activity.title}"',
      date: activity.date,
      authorName: user.displayName,
      authorPhotoUrl: user.photoUrl,
      type: isNowDone ? NotificationType.done : NotificationType.undone,
      createdAt: DateTime.now(),
      isRead: true,
    );

    // 1. Instant optimistic state update
    final updatedList = state.activities.map((a) {
      return a.id == activity.id ? updated : a;
    }).toList();
    state = state.copyWith(
      activities: updatedList,
      notifications: [notif, ...state.notifications],
    );

    // 2. Persist and sync
    await _planService.saveActivity(activity: updated, user: user);
    await _planService.logNotification(spaceId: activity.spaceId, notification: notif);
  }

  Future<void> deleteActivity(PlanActivity activity) async {
    final user = _getCurrentUser();

    final notif = ActivityNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: activity.spaceId,
      title: '${user.displayName} removed "${activity.title}"',
      date: activity.date,
      authorName: user.displayName,
      authorPhotoUrl: user.photoUrl,
      type: NotificationType.delete,
      createdAt: DateTime.now(),
      isRead: true,
    );

    // 1. Instant optimistic state update
    final updatedList = state.activities.where((a) => a.id != activity.id).toList();
    state = state.copyWith(
      activities: updatedList,
      notifications: [notif, ...state.notifications],
    );

    // 2. Persist and sync
    await _planService.deleteActivity(activity: activity, user: user);
    await _planService.logNotification(spaceId: activity.spaceId, notification: notif);
  }

  @override
  void dispose() {
    _noticeAutoDismissTimer?.cancel();
    _activitySubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final planServiceProvider = Provider<PlanService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return PlanService(storageService, notificationService);
});

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>((ref) {
  final planService = ref.watch(planServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return PlanNotifier(planService, storageService, ref);
});
