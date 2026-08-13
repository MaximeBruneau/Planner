import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_sync_service.dart';
import 'mood_provider.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isSignedIn => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthSyncService _authSyncService;
  final Ref _ref;

  AuthNotifier(this._authSyncService, this._ref)
      : super(AuthState(user: _authSyncService.currentUser)) {
    _init();
  }

  Future<void> _init() async {
    await _authSyncService.init();
    state = AuthState(user: _authSyncService.currentUser);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authSyncService.signInWithGoogle();
      state = AuthState(user: user, isLoading: false);
      if (user != null) {
        // Refresh mood provider data after sync
        _ref.read(moodProvider.notifier).loadEntries();
      }
    } catch (e) {
      state = AuthState(
        user: null,
        isLoading: false,
        errorMessage: 'Failed to sign in with Google',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authSyncService.signOut();
    state = const AuthState(user: null, isLoading: false);
  }

  Future<void> triggerSync() async {
    state = state.copyWith(isLoading: true);
    await _authSyncService.syncCloudData();
    _ref.read(moodProvider.notifier).loadEntries();
    state = state.copyWith(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authSync = ref.watch(authSyncServiceProvider);
  return AuthNotifier(authSync, ref);
});
