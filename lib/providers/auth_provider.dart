import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../core/services/auth_sync_service.dart';
import '../core/services/storage_service.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isSignedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthSyncService _authSyncService;

  AuthNotifier(this._authSyncService)
      : super(AuthState(user: _authSyncService.currentUser)) {
    _init();
  }

  Future<void> _init() async {
    await _authSyncService.init();
    state = AuthState(user: _authSyncService.currentUser);
  }

  Future<AppUser?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authSyncService.signInWithGoogle();
      if (user != null) {
        state = AuthState(user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sign in with Google. Please try again.',
      );
      return null;
    }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authSyncService.signInWithEmail(email, password);
      state = AuthState(user: user, isLoading: false);
      return user;
    } catch (e) {
      final errMessage = _parseAuthError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: errMessage,
      );
      return null;
    }
  }

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authSyncService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AuthState(user: user, isLoading: false);
      return user;
    } catch (e) {
      final errMessage = _parseAuthError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: errMessage,
      );
      return null;
    }
  }

  Future<AppUser> startAsGuest({String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final user = await _authSyncService.startAsGuest(name: name);
    state = AuthState(user: user, isLoading: false);
    return user;
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authSyncService.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final errMessage = _parseAuthError(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: errMessage,
      );
      return false;
    }
  }

  String _parseAuthError(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('operation-not-allowed')) {
      return 'Email/Password sign-in is disabled in Firebase Console. Please enable it under Authentication > Sign-in method.';
    } else if (str.contains('user-not-found') ||
        str.contains('invalid-credential') ||
        str.contains('wrong-password')) {
      return 'Incorrect email or password. Please check and try again.';
    } else if (str.contains('email-already-in-use')) {
      return 'An account with this email already exists. Try signing in instead.';
    } else if (str.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (str.contains('weak-password')) {
      return 'Password is too weak. Please use at least 6 characters.';
    } else if (str.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Authentication error: ${error.toString().split(']').last.trim()}';
  }

  Future<bool> updateDisplayName(String newName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _authSyncService.updateDisplayName(newName);
      if (updated != null) {
        state = AuthState(user: updated, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update nickname. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authSyncService.signOut();
    state = const AuthState(user: null, isLoading: false);
  }

  Future<bool> deleteAccountAndData() async {
    state = state.copyWith(isLoading: true);
    final success = await _authSyncService.deleteAccountAndData();
    state = const AuthState(user: null, isLoading: false);
    return success;
  }
}

final authSyncServiceProvider = Provider<AuthSyncService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AuthSyncService(storageService);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authSync = ref.watch(authSyncServiceProvider);
  return AuthNotifier(authSync);
});
