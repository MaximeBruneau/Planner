import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_idea.dart';
import '../models/activity_notification.dart';
import '../models/app_user.dart';
import '../core/services/idea_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/plan_service.dart';
import 'auth_provider.dart';
import 'space_provider.dart';
import 'plan_provider.dart';

class IdeaState {
  final List<BankIdea> ideas;
  final IdeaCategory? selectedCategory;
  final String searchQuery;
  final String sortBy; // 'upvotes' | 'recent'
  final bool isLoading;
  final String? lastInAppNotice;

  const IdeaState({
    this.ideas = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.sortBy = 'upvotes',
    this.isLoading = false,
    this.lastInAppNotice,
  });

  int get totalCount => ideas.length;

  int countForCategory(IdeaCategory category) {
    return ideas.where((i) => i.category == category && !i.deleted).length;
  }

  List<BankIdea> get filteredIdeas {
    var list = ideas.where((i) => !i.deleted).toList();

    if (selectedCategory != null) {
      list = list.where((i) => i.category == selectedCategory).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((i) {
        final titleMatch = i.title.toLowerCase().contains(q);
        final noteMatch = i.note?.toLowerCase().contains(q) ?? false;
        return titleMatch || noteMatch;
      }).toList();
    }

    if (sortBy == 'upvotes') {
      list.sort((a, b) {
        if (b.upvoteCount != a.upvoteCount) {
          return b.upvoteCount.compareTo(a.upvoteCount);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  IdeaState copyWith({
    List<BankIdea>? ideas,
    IdeaCategory? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    String? sortBy,
    bool? isLoading,
    String? lastInAppNotice,
    bool clearNotice = false,
  }) {
    return IdeaState(
      ideas: ideas ?? this.ideas,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      lastInAppNotice: clearNotice ? null : (lastInAppNotice ?? this.lastInAppNotice),
    );
  }
}

class IdeaNotifier extends StateNotifier<IdeaState> {
  final IdeaService _ideaService;
  final StorageService _storageService;
  final PlanService _planService;
  final Ref _ref;
  StreamSubscription<List<BankIdea>>? _ideaSubscription;
  Timer? _noticeTimer;

  IdeaNotifier(this._ideaService, this._storageService, this._planService, this._ref)
      : super(const IdeaState()) {
    _init();
  }

  void _init() {
    final currentSpace = _ref.read(spaceProvider).currentSpace;
    if (currentSpace != null) {
      final cached = _storageService.getSpaceIdeas(currentSpace.id);
      state = state.copyWith(ideas: cached);
      _subscribeToSpace(currentSpace.id);
    }

    _ref.listen<SpaceState>(spaceProvider, (prev, next) {
      if (next.currentSpace != null) {
        final cached = _storageService.getSpaceIdeas(next.currentSpace!.id);
        state = state.copyWith(ideas: cached);
        _subscribeToSpace(next.currentSpace!.id);
      } else {
        _ideaSubscription?.cancel();
        state = const IdeaState();
      }
    });
  }

  void _subscribeToSpace(String spaceId) {
    if (spaceId == 'space_default') return;
    _ideaSubscription?.cancel();

    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    _ideaSubscription = _ideaService.streamSpaceIdeas(
      spaceId: spaceId,
      currentUser: user,
      onGroupIdeaNotice: (notice) {
        _displayNotice(notice);
      },
    ).listen((ideas) {
      state = state.copyWith(ideas: ideas, isLoading: false);
    });
  }

  void _displayNotice(String notice) {
    _noticeTimer?.cancel();
    state = state.copyWith(lastInAppNotice: notice);
    _noticeTimer = Timer(const Duration(seconds: 2), () {
      state = state.copyWith(clearNotice: true);
    });
  }

  void setSelectedCategory(IdeaCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// Pick a random idea from the bank (or from a specific category) 🎲
  BankIdea? pickRandomIdea({IdeaCategory? category}) {
    List<BankIdea> candidates;
    if (category != null) {
      candidates = state.ideas.where((i) => i.category == category && !i.deleted).toList();
    } else if (state.selectedCategory != null) {
      candidates = state.ideas.where((i) => i.category == state.selectedCategory && !i.deleted).toList();
      if (candidates.isEmpty) {
        candidates = state.ideas.where((i) => !i.deleted).toList();
      }
    } else {
      candidates = state.ideas.where((i) => !i.deleted).toList();
    }

    if (candidates.isEmpty) return null;
    final random = Random();
    return candidates[random.nextInt(candidates.length)];
  }

  /// Add a new idea to the bank with instant optimistic update
  Future<void> addIdea({
    required String title,
    required IdeaCategory category,
    String? note,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');
    final space = _ref.read(spaceProvider).currentSpace;
    final spaceId = space?.id ?? 'space_default';

    final idea = BankIdea(
      id: 'idea_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: spaceId,
      title: cleanTitle,
      category: category,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      creatorId: user.id,
      creatorName: user.displayName,
      creatorPhotoUrl: user.photoUrl,
      upvoterIds: [user.id],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notif = ActivityNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      spaceId: spaceId,
      title: '${user.displayName} added idea "$cleanTitle" ${category.emoji}',
      date: '',
      authorName: user.displayName,
      authorPhotoUrl: user.photoUrl,
      type: NotificationType.ideaAdd,
      createdAt: DateTime.now(),
      isRead: true,
    );

    // 1. Optimistic update
    state = state.copyWith(ideas: [idea, ...state.ideas.where((i) => i.id != idea.id)]);

    // 2. Persist & sync
    await _ideaService.saveIdea(idea: idea, user: user);
    await _planService.logNotification(spaceId: spaceId, notification: notif);
  }

  /// Toggle upvote 👍
  Future<void> toggleUpvote(BankIdea idea) async {
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    final upvoters = List<String>.from(idea.upvoterIds);
    final hasVoted = upvoters.contains(user.id);
    if (hasVoted) {
      upvoters.remove(user.id);
    } else {
      upvoters.add(user.id);
    }

    final updated = idea.copyWith(
      upvoterIds: upvoters,
      updatedAt: DateTime.now(),
    );

    // 1. Optimistic update
    final updatedList = state.ideas.map((i) => i.id == idea.id ? updated : i).toList();
    state = state.copyWith(ideas: updatedList);

    // 2. Persist & sync
    await _ideaService.saveIdea(idea: updated, user: user);

    if (!hasVoted) {
      final notif = ActivityNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        spaceId: idea.spaceId,
        title: '${user.displayName} upvoted idea "${idea.title}" ${idea.category.emoji}',
        date: '',
        authorName: user.displayName,
        authorPhotoUrl: user.photoUrl,
        type: NotificationType.ideaUpvote,
        createdAt: DateTime.now(),
        isRead: true,
      );
      await _planService.logNotification(spaceId: idea.spaceId, notification: notif);
    }
  }

  /// Delete an idea
  Future<void> deleteIdea(BankIdea idea) async {
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

    // 1. Optimistic update
    final updatedList = state.ideas.where((i) => i.id != idea.id).toList();
    state = state.copyWith(ideas: updatedList);

    // 2. Persist & sync
    await _ideaService.deleteIdea(idea: idea, user: user);
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _ideaSubscription?.cancel();
    super.dispose();
  }
}

final ideaServiceProvider = Provider<IdeaService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return IdeaService(storageService, notificationService);
});

final ideaProvider = StateNotifierProvider<IdeaNotifier, IdeaState>((ref) {
  final ideaService = ref.watch(ideaServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final planService = ref.watch(planServiceProvider);
  return IdeaNotifier(ideaService, storageService, planService, ref);
});
