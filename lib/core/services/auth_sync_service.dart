import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _currentUser = _storageService.getSavedUser();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;

      if (kIsWeb) {
        try {
          final redirectResult = await FirebaseAuth.instance.getRedirectResult();
          if (redirectResult.user != null) {
            final fbUser = redirectResult.user!;
            _currentUser = AppUser(
              id: fbUser.uid,
              email: fbUser.email ?? '',
              displayName: fbUser.displayName ?? (fbUser.email?.split('@')[0] ?? 'Planner User'),
              photoUrl: fbUser.photoURL,
            );
            await _storageService.saveUser(_currentUser);
            await _syncUserDataFromCloud();
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
          displayName: fbUser.displayName ?? (fbUser.email?.split('@')[0] ?? 'Planner User'),
          photoUrl: fbUser.photoURL,
        );
        await _storageService.saveUser(_currentUser);
      }

      if (_currentUser != null) {
        await _syncUserDataFromCloud();
      }
    } catch (e) {
      debugPrint('Firebase init notice: $e');
      _isFirebaseInitialized = false;
    }
  }

  Future<void> _syncUserDataFromCloud() async {
    if (!_isFirebaseInitialized || _currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.id).get();
      if (doc.exists && doc.data() != null) {
        final cloudUser = AppUser.fromMap(doc.data()!);
        _currentUser = cloudUser;
        await _storageService.saveUser(_currentUser);
      }
    } catch (e) {
      debugPrint('Sync user data notice: $e');
    }
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In for Super Planner...');

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
              displayName: fbUser.displayName ?? (fbUser.email?.split('@')[0] ?? 'Planner User'),
              photoUrl: fbUser.photoURL,
            );
            await _storageService.saveUser(_currentUser);
            await _syncUserDataFromCloud();
            return _currentUser;
          }
        } catch (popupError) {
          debugPrint('Popup sign in error (trying redirect): $popupError');
          await FirebaseAuth.instance.signInWithRedirect(googleProvider);
          return null;
        }
        return null;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        return null;
      }

      _currentUser = AppUser(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
        photoUrl: googleUser.photoUrl,
      );
      await _storageService.saveUser(_currentUser);

      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
          await _syncUserDataFromCloud();
        }
      } catch (fbError) {
        debugPrint('Firebase linking notice: $fbError');
      }

      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign In error: $e');
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
        displayName: fbUser.displayName ?? (fbUser.email?.split('@')[0] ?? 'Planner User'),
        photoUrl: fbUser.photoURL,
      );
      await _storageService.saveUser(_currentUser);
      await _syncUserDataFromCloud();
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
        debugPrint('Firestore user create notice: $e');
      }

      return _currentUser;
    }
    return null;
  }

  /// Quick Guest / Offline Mode
  Future<AppUser> startAsGuest({String? name}) async {
    final guestName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Guest Planner';
    final id = 'guest_${DateTime.now().millisecondsSinceEpoch}';

    _currentUser = AppUser(
      id: id,
      email: '',
      displayName: guestName,
    );
    await _storageService.saveUser(_currentUser);
    return _currentUser!;
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

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (_isFirebaseInitialized) {
        await FirebaseAuth.instance.signOut();
      }
      _currentUser = null;
      await _storageService.saveUser(null);
      await _storageService.saveCurrentSpace(null);
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }

  /// Delete account and data (GDPR Compliant)
  Future<bool> deleteAccountAndData() async {
    try {
      final uid = _currentUser?.id;
      final firestore = FirebaseFirestore.instance;

      if (uid != null && uid.isNotEmpty && _isFirebaseInitialized) {
        try {
          await firestore.collection('users').doc(uid).delete();
        } catch (_) {}

        try {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null) {
            await fbUser.delete();
          }
        } catch (_) {}
      }

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      await _storageService.clearAll();
      _currentUser = null;
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }
}
