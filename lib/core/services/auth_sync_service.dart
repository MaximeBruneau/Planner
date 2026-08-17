import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/mood_entry.dart';
import '../../models/app_user.dart';
import '../../firebase_options.dart';
import 'storage_service.dart';

class AuthSyncService {
  final StorageService _storageService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '850562549978-i50kisru72t3dv8649alfmc1mliv97dd.apps.googleusercontent.com'
        : (defaultTargetPlatform == TargetPlatform.iOS
            ? '850562549978-nsemf5qk36gq707f3pj2u6k3ehe22dsd.apps.googleusercontent.com'
            : null),
    serverClientId:
        '850562549978-i50kisru72t3dv8649alfmc1mliv97dd.apps.googleusercontent.com',
  );



  AppUser? _currentUser;
  bool _isFirebaseInitialized = false;

  AuthSyncService(this._storageService);

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> init() async {
    // 1. Restore local cached user session
    _currentUser = _storageService.getSavedUser();

    // 2. Try Firebase initialization
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;

      if (kIsWeb) {
        try {
          final redirectResult =
              await FirebaseAuth.instance.getRedirectResult();
          if (redirectResult.user != null) {
            final fbUser = redirectResult.user!;
            _currentUser = AppUser(
              id: fbUser.uid,
              email: fbUser.email ?? '',
              displayName: fbUser.displayName ??
                  (fbUser.email?.split('@')[0] ?? 'User'),
              photoUrl: fbUser.photoURL,
            );
            await _storageService.saveUser(_currentUser);
            await syncCloudData();
          }
        } catch (e) {
          debugPrint('Redirect auth check notice: $e');
        }
      }

      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null && _currentUser == null) {
        _currentUser = AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          displayName:
              fbUser.displayName ?? (fbUser.email?.split('@')[0] ?? 'User'),
          photoUrl: fbUser.photoURL,
        );
        await _storageService.saveUser(_currentUser);
      }
    } catch (e) {
      debugPrint('Firebase init notice (local-first mode): $e');
      _isFirebaseInitialized = false;
    }

    // 3. Try silent sign-in with Google if available
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        _currentUser = AppUser(
          id: googleUser.id,
          email: googleUser.email,
          displayName:
              googleUser.displayName ?? googleUser.email.split('@')[0],
          photoUrl: googleUser.photoUrl,
        );
        await _storageService.saveUser(_currentUser);
      }
    } catch (e) {
      debugPrint('Silent Google Sign In notice: $e');
    }
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In flow...');

      if (kIsWeb) {
        if (!_isFirebaseInitialized) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          _isFirebaseInitialized = true;
        }
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        try {
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithPopup(googleProvider);
          final User? fbUser = userCredential.user;
          if (fbUser != null) {
            _currentUser = AppUser(
              id: fbUser.uid,
              email: fbUser.email ?? '',
              displayName: fbUser.displayName ??
                  (fbUser.email?.split('@')[0] ?? 'User'),
              photoUrl: fbUser.photoURL,
            );
            await _storageService.saveUser(_currentUser);
            await syncCloudData();
            return _currentUser;
          }
        } catch (popupError) {
          debugPrint('Popup sign in error (trying redirect for Safari): $popupError');
          final errStr = popupError.toString().toLowerCase();
          if (errStr.contains('popup') ||
              errStr.contains('blocked') ||
              errStr.contains('cancelled') ||
              errStr.contains('closed')) {
            await FirebaseAuth.instance.signInWithRedirect(googleProvider);
            return null;
          }
          rethrow;
        }
        return null;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        return null;
      }

      debugPrint('Google user selected: ${googleUser.email}');

      // Create and persist AppUser immediately
      _currentUser = AppUser(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
        photoUrl: googleUser.photoUrl,
      );
      await _storageService.saveUser(_currentUser);

      // Attempt Firebase linking & cloud backup if Firebase credentials & network are available
      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken != null || googleAuth.accessToken != null) {
          if (!_isFirebaseInitialized) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            _isFirebaseInitialized = true;
          }

          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await FirebaseAuth.instance.signInWithCredential(credential);
          await syncCloudData();
        }
      } catch (fbError) {
        debugPrint('Firebase/Cloud linking notice (offline/local mode active): $fbError');
      }

      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign In general error: $e');
      return _currentUser;
    }
  }

  /// Manually set or update user profile (e.g. for offline / custom profile)
  Future<AppUser> setUserProfile({
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    _currentUser = AppUser(
      id: _currentUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      email: email.trim(),
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'Friend 🌸',
      photoUrl: photoUrl,
    );
    await _storageService.saveUser(_currentUser);
    return _currentUser!;
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (_isFirebaseInitialized) {
        await FirebaseAuth.instance.signOut();
      }
      _currentUser = null;
      await _storageService.saveUser(null);
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }

  /// Backup local entries to Firestore and restore cloud entries
  Future<void> syncCloudData() async {
    if (!_isFirebaseInitialized || _currentUser == null) return;

    try {
      final uid = _currentUser!.id;
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('users').doc(uid).collection('mood_entries');

      // 1. Upload local entries to cloud
      final localEntries = _storageService.getAllEntries();
      for (final entry in localEntries.values) {
        await collection.doc(entry.date).set(entry.toMap(), SetOptions(merge: true));
      }

      // 2. Download cloud entries to local DB
      final snapshot = await collection.get();
      final cloudEntries = <String, MoodEntry>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final entry = MoodEntry.fromMap(data);
        cloudEntries[entry.date] = entry;
      }

      // Merge and save to local storage
      final mergedEntries = Map<String, MoodEntry>.from(localEntries)..addAll(cloudEntries);
      await _storageService.saveAllEntries(mergedEntries);
    } catch (e) {
      debugPrint('Cloud sync error: $e');
    }
  }

  /// Backup a single entry to Firestore asynchronously
  Future<void> backupSingleEntry(MoodEntry entry) async {
    if (!_isFirebaseInitialized || _currentUser == null) return;
    try {
      final uid = _currentUser!.id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mood_entries')
          .doc(entry.date)
          .set(entry.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Single entry backup error: $e');
    }
  }

  /// Delete an entry from Firestore
  Future<void> deleteCloudEntry(String dateStr) async {
    if (!_isFirebaseInitialized || _currentUser == null) return;
    try {
      final uid = _currentUser!.id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mood_entries')
          .doc(dateStr)
          .delete();
    } catch (e) {
      debugPrint('Delete cloud entry error: $e');
    }
  }
}
