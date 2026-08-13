import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/mood_entry.dart';
import 'storage_service.dart';

class AuthSyncService {
  final StorageService _storageService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _currentUser;
  bool _isFirebaseInitialized = false;

  AuthSyncService(this._storageService);

  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      _currentUser = FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Firebase init notice (running in local fallback mode): $e');
      _isFirebaseInitialized = false;
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      if (!_isFirebaseInitialized) {
        await init();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled by user

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      _currentUser = userCredential.user;

      // Sync data after successful login
      if (_currentUser != null) {
        await syncCloudData();
      }

      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return null;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (_isFirebaseInitialized) {
        await FirebaseAuth.instance.signOut();
      }
      _currentUser = null;
    } catch (e) {
      debugPrint('Sign Out Error: $e');
    }
  }

  /// Backup local entries to Firestore and restore cloud entries
  Future<void> syncCloudData() async {
    if (!_isFirebaseInitialized || _currentUser == null) return;

    try {
      final uid = _currentUser!.uid;
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
      final uid = _currentUser!.uid;
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
      final uid = _currentUser!.uid;
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
