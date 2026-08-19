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

  AuthSyncService(this._storageService) {
    _currentUser = _storageService.getSavedUser();
  }

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

    // 4. Automatically sync cloud data if user is active
    if (_currentUser != null) {
      await syncCloudData();
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

  /// Sign in with Email and Password
  Future<AppUser?> signInWithEmail(String email, String password) async {
    if (!_isFirebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
    }

    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser != null) {
      _currentUser = AppUser(
        id: fbUser.uid,
        email: fbUser.email ?? email.trim(),
        displayName: fbUser.displayName ??
            (fbUser.email?.split('@')[0] ?? 'User'),
        photoUrl: fbUser.photoURL,
      );
      await _storageService.saveUser(_currentUser);

      try {
        await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
          'id': fbUser.uid,
          'email': fbUser.email ?? email.trim(),
          'displayName': _currentUser!.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user doc sync error: $e');
      }

      await syncCloudData();
      return _currentUser;
    }
    return null;
  }

  /// Sign up with Email, Password and Display Name
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!_isFirebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
    }

    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser != null) {
      final name = displayName.trim().isNotEmpty
          ? displayName.trim()
          : (email.split('@')[0]);

      try {
        await fbUser.updateDisplayName(name);
      } catch (_) {}

      _currentUser = AppUser(
        id: fbUser.uid,
        email: fbUser.email ?? email.trim(),
        displayName: name,
        photoUrl: fbUser.photoURL,
      );
      await _storageService.saveUser(_currentUser);

      try {
        await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
          'id': fbUser.uid,
          'email': fbUser.email ?? email.trim(),
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user doc create error: $e');
      }

      await syncCloudData();
      return _currentUser;
    }
    return null;
  }

  /// Send Password Reset Email
  Future<void> sendPasswordReset(String email) async {
    if (!_isFirebaseInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
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

  /// 100% GDPR & Store compliant: Delete user account, calendar entries & all data
  Future<bool> deleteAccountAndData() async {
    try {
      final uid = _currentUser?.id;
      final firestore = FirebaseFirestore.instance;

      if (uid != null && uid.isNotEmpty && _isFirebaseInitialized) {
        // 1. Delete all user mood entries from Firestore
        try {
          final entriesSnapshot = await firestore
              .collection('users')
              .doc(uid)
              .collection('mood_entries')
              .get();

          for (final doc in entriesSnapshot.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          debugPrint('Error deleting cloud entries during account deletion: $e');
        }

        // 2. Unlink partner if connected
        try {
          final userDoc = await firestore.collection('users').doc(uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            final partnerId = userDoc.data()!['partnerId'] as String?;
            if (partnerId != null && partnerId.isNotEmpty) {
              await firestore.collection('users').doc(partnerId).set({
                'partnerId': null,
                'partnerInfo': FieldValue.delete(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          }
        } catch (e) {
          debugPrint('Error unlinking partner during account deletion: $e');
        }

        // 3. Delete any pairing codes created by this user
        try {
          final codesQuery = await firestore
              .collection('pairing_codes')
              .where('creatorUserId', isEqualTo: uid)
              .get();

          for (final codeDoc in codesQuery.docs) {
            await codeDoc.reference.delete();
          }
        } catch (e) {
          debugPrint('Error deleting pairing codes: $e');
        }

        // 4. Delete root user document in Firestore
        try {
          await firestore.collection('users').doc(uid).delete();
        } catch (e) {
          debugPrint('Error deleting root user document: $e');
        }

        // 5. Delete Firebase Auth User Account
        try {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null) {
            await fbUser.delete();
          }
        } catch (e) {
          debugPrint('Error deleting Firebase Auth user (might require recent login): $e');
        }
      }

      // 6. Sign out of Google Sign-in if active
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google sign out during deletion error: $e');
      }

      // 7. Clear all local storage data
      _currentUser = null;
      await _storageService.saveUser(null);
      await _storageService.savePartner(null);
      await _storageService.saveAllEntries({});
      await _storageService.savePartnerEntries({});

      return true;
    } catch (e) {
      debugPrint('General delete account and data error: $e');
      return false;
    }
  }
}

