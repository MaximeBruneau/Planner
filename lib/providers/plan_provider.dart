import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/plan_activity.dart';
import '../../models/app_user.dart';
import '../../core/utils/date_utils_helper.dart';
import '../core/services/plan_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import 'auth_provider.dart';
import 'space_provider.dart';

class PlanState {
  final List<PlanActivity> activities;
  final bool isLoading;
  final String? lastInAppNotice;

  const PlanState({
    this.activities = const [],
    this.isLoading = false,
    this.lastInAppNotice,
  });

  PlanState copyWith({
    List<PlanActivity>? activities,
    bool? isLoading,
    String? lastInAppNotice,
    bool clearNotice = false,
  }) {
    return PlanState(
      activities: activities ?? this.activities,
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

  PlanNotifier(this._planService, this._storageService, this._ref)
      : super(const PlanState()) {
    _init();
  }

  void _init() {
    final currentSpace = _ref.read(spaceProvider).currentSpace;
    if (currentSpace != null) {
      final cached = _storageService.getSpaceActivities(currentSpace.id);
      state = state.copyWith(activities: cached);
      _subscribeToSpace(currentSpace.id);
    }

    _ref.listen<SpaceState>(spaceProvider, (previous, next) {
      if (next.currentSpace != null) {
        final cached = _storageService.getSpaceActivities(next.currentSpace!.id);
        state = state.copyWith(activities: cached);
        _subscribeToSpace(next.currentSpace!.id);
      } else {
        _activitySubscription?.cancel();
        state = const PlanState();
      }
    });
  }

  void _subscribeToSpace(String spaceId) {
    if (spaceId == 'space_default') return;
    _activitySubscription?.cancel();
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    _activitySubscription = _planService.streamSpaceActivities(
      spaceId: spaceId,
      currentUser: user,
      onGroupActivityNotice: (notice) {
        state = state.copyWith(lastInAppNotice: notice);
      },
    ).listen((activities) {
      state = state.copyWith(activities: activities, isLoading: false);
    });
  }

  void clearNotice() {
    state = state.copyWith(clearNotice: true);
  }

  // --- Filtering & Date Helpers ---

  List<PlanActivity> getActivitiesForDate(DateTime date) {
    final dateStr = DateUtilsHelper.formatDate(date);
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
    final dateStr = DateUtilsHelper.formatDate(date);
    return state.activities.any((a) => a.date == dateStr && !a.deleted);
  }

  int getCountForDate(DateTime date) {
    final dateStr = DateUtilsHelper.formatDate(date);
    return state.activities.where((a) => a.date == dateStr && !a.deleted).length;
  }

  // --- Actions with Instant Optimistic UI Update ---

  Future<void> addItem({
    required String text,
    required DateTime date,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');
    final space = _ref.read(spaceProvider).currentSpace;
    final spaceId = space?.id ?? 'space_default';
    final dateStr = DateUtilsHelper.formatDate(date);

    final item = PlanActivity(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: spaceId,
      date: dateStr,
      title: trimmed,
      creatorId: user.id,
      creatorName: user.displayName,
      creatorPhotoUrl: user.photoUrl,
      upvoterIds: [user.id],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Instant optimistic state update
    state = state.copyWith(
      activities: [item, ...state.activities.where((a) => a.id != item.id)],
    );

    // 2. Persist locally and sync to cloud
    await _planService.saveActivity(activity: item, user: user);
  }

  Future<void> toggleUpvote(PlanActivity activity) async {
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    final upvoters = List<String>.from(activity.upvoterIds);
    if (upvoters.contains(user.id)) {
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
  }

  Future<void> toggleDone(PlanActivity activity) async {
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    final updated = activity.copyWith(
      isDone: !activity.isDone,
      updatedAt: DateTime.now(),
    );

    // 1. Instant optimistic state update
    final updatedList = state.activities.map((a) {
      return a.id == activity.id ? updated : a;
    }).toList();
    state = state.copyWith(activities: updatedList);

    // 2. Persist and sync
    await _planService.saveActivity(activity: updated, user: user);
  }

  Future<void> deleteActivity(PlanActivity activity) async {
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    // 1. Instant optimistic state update
    final updatedList = state.activities.where((a) => a.id != activity.id).toList();
    state = state.copyWith(activities: updatedList);

    // 2. Persist and sync
    await _planService.deleteActivity(activity: activity, user: user);
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
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
