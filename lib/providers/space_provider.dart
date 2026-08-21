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
    final cached = _storageService.getCurrentSpace();
    if (cached != null) {
      state = state.copyWith(currentSpace: cached);
      _listenToSpace(cached.id);
      return;
    }

    if (user.currentSpaceId != null && user.currentSpaceId!.isNotEmpty) {
      state = state.copyWith(isLoading: true);
      final space = await _spaceService.fetchSpace(user.currentSpaceId!);
      if (space != null) {
        state = state.copyWith(currentSpace: space, isLoading: false);
        _listenToSpace(space.id);
        return;
      }
    }

    // Auto-create initial personal/group shared space
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

  /// Create a new shared space
  Future<SharedSpace?> createSpace({required String name}) async {
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

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
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');

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
    final user = _ref.read(authProvider).user ??
        AppUser(id: 'local_user', displayName: 'Planner Friend', email: '');
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
