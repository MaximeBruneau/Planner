import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shared_space.dart';
import '../../models/app_user.dart';
import '../core/services/space_service.dart';
import '../core/services/storage_service.dart';
import 'auth_provider.dart';

class SpaceState {
  final SharedSpace? currentSpace;
  final bool isLoading;
  final String? errorMessage;

  const SpaceState({
    this.currentSpace,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasSpace => currentSpace != null;

  SpaceState copyWith({
    SharedSpace? currentSpace,
    bool clearSpace = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SpaceState(
      currentSpace: clearSpace ? null : (currentSpace ?? this.currentSpace),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SpaceNotifier extends StateNotifier<SpaceState> {
  final SpaceService _spaceService;
  final StorageService _storageService;
  final Ref _ref;
  StreamSubscription<SharedSpace?>? _spaceSubscription;

  SpaceNotifier(this._spaceService, this._storageService, this._ref)
      : super(SpaceState(
          currentSpace: _storageService.getCurrentSpace() ??
              SharedSpace(
                id: 'space_default',
                name: 'Our Shared Calendar 🗓️',
                code: 'SUPER-7788',
                creatorId: 'local_user',
                memberIds: ['local_user'],
              ),
        )) {
    _initListener();
  }

  void _initListener() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isSignedIn && next.user != null) {
        ensureSpaceForUser(next.user!);
      }
    });

    final currentUser = _ref.read(authProvider).user;
    if (currentUser != null) {
      ensureSpaceForUser(currentUser);
    } else {
      final cached = _storageService.getCurrentSpace();
      if (cached != null) {
        state = state.copyWith(currentSpace: cached);
      }
    }
  }

  /// Ensure the user is connected to a shared space (or create their first one)
  Future<void> ensureSpaceForUser(AppUser user) async {
    // 1. If user document has a designated cloud space, load it first
    if (user.currentSpaceId != null && user.currentSpaceId!.isNotEmpty) {
      state = state.copyWith(isLoading: true);
      final space = await _spaceService.fetchSpace(user.currentSpaceId!);
      if (space != null) {
        state = state.copyWith(currentSpace: space, isLoading: false);
        _listenToSpace(space.id);
        await _spaceService.syncOrUpdateMember(spaceId: space.id, user: user);
        return;
      }
    }

    // 2. Otherwise check local cached space
    final cached = _storageService.getCurrentSpace();
    if (cached != null && cached.id != 'space_default') {
      state = state.copyWith(currentSpace: cached);
      _listenToSpace(cached.id);
      await _spaceService.syncOrUpdateMember(spaceId: cached.id, user: user);
      return;
    }

    // 3. Auto-create initial personal/group shared space if none exists
    await createSpace(
      name: "${user.displayName}'s Calendar 🗓️",
    );
  }

  void _listenToSpace(String spaceId) {
    if (spaceId == 'space_default') return;
    _spaceSubscription?.cancel();
    _spaceSubscription = _spaceService.streamSpace(spaceId).listen((space) {
      if (space != null) {
        state = state.copyWith(currentSpace: space);
      }
    });
  }

  AppUser _getCurrentUser() {
    return _ref.read(authProvider).user ??
        _storageService.getSavedUser() ??
        AppUser(id: 'local_user', displayName: 'Planner User', email: '');
  }

  /// Create a new shared space
  Future<SharedSpace?> createSpace({required String name}) async {
    final user = _getCurrentUser();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final space = await _spaceService.createSpace(name: name, creator: user);
      state = state.copyWith(currentSpace: space, isLoading: false);
      _listenToSpace(space.id);
      return space;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Join an existing space with a code
  Future<bool> joinSpace(String code) async {
    final user = _getCurrentUser();

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final space = await _spaceService.joinSpaceByCode(code: code, user: user);
      state = state.copyWith(currentSpace: space, isLoading: false);
      _listenToSpace(space.id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Leave current space
  Future<void> leaveSpace() async {
    final user = _getCurrentUser();
    final space = state.currentSpace;
    if (space == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await _spaceService.leaveSpace(spaceId: space.id, userId: user.id);
      _spaceSubscription?.cancel();
      state = state.copyWith(clearSpace: true, isLoading: false);

      // Create new fresh personal space
      await createSpace(name: "${user.displayName}'s Calendar 🗓️");
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Update the current user's member display name inside the active space
  Future<void> updateMyMemberName(String newName) async {
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    final user = _ref.read(authProvider).user;
    final space = state.currentSpace;
    if (user == null || space == null) return;

    if (space.id != 'space_default') {
      final updatedSpace = await _spaceService.syncOrUpdateMember(
        spaceId: space.id,
        user: user,
        newDisplayName: cleanName,
      );
      if (updatedSpace != null) {
        state = state.copyWith(currentSpace: updatedSpace);
      }
    }
  }

  /// Remove a member from the current space
  Future<void> removeMember(String memberId) async {
    final space = state.currentSpace;
    if (space == null || memberId.isEmpty || space.id == 'space_default') return;

    final updatedMembers = Map<String, SpaceMember>.from(space.members)..remove(memberId);
    final updatedMemberIds = List<String>.from(space.memberIds)..remove(memberId);
    final updatedSpace = space.copyWith(
      memberIds: updatedMemberIds,
      members: updatedMembers,
    );
    state = state.copyWith(currentSpace: updatedSpace);
    await _storageService.saveCurrentSpace(updatedSpace);

    await _spaceService.removeMember(spaceId: space.id, memberId: memberId);
  }

  /// Update the current space name
  Future<void> updateSpaceName(String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    final space = state.currentSpace;
    if (space == null || space.id == 'space_default') return;

    final updated = space.copyWith(name: clean);
    state = state.copyWith(currentSpace: updated);
    await _storageService.saveCurrentSpace(updated);
    await _spaceService.updateSpaceName(spaceId: space.id, newName: clean);
  }

  @override
  void dispose() {
    _spaceSubscription?.cancel();
    super.dispose();
  }
}

final spaceServiceProvider = Provider<SpaceService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SpaceService(storageService);
});

final spaceProvider = StateNotifierProvider<SpaceNotifier, SpaceState>((ref) {
  final spaceService = ref.watch(spaceServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return SpaceNotifier(spaceService, storageService, ref);
});
