import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Authentication service backed by Firebase Auth and Cloud Firestore.
///
/// On register: creates a Firebase Auth account, then writes the user
/// profile to the `users` collection with the Auth UID as document ID.
/// On login: authenticates via Firebase Auth, then fetches the Firestore profile.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null && _currentUser != null;
  bool get isLoading => _isLoading;

  /// Initializes the service by checking for an existing Firebase session.
  Future<void> initializeAuth() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _fetchUserProfile(firebaseUser.uid);
    }
  }

  /// Registers a new user with Firebase Auth and saves the profile to Firestore.
  /// Returns `null` on success, or a user-friendly error message on failure.
  Future<String?> registerUser({
    required String nama,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final userModel = UserModel(
        uid: uid,
        nama: nama,
        email: email,
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userModel.toFirestore());

      // Sign out after registration so user logs in explicitly
      await _auth.signOut();
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _mapAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  /// Authenticates a user via Firebase Auth and loads their Firestore profile.
  /// Returns `null` on success, or a user-friendly error message on failure.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _fetchUserProfile(credential.user!.uid);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _mapAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  /// Signs out and clears local state.
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Fetches the user profile document from Firestore `users` collection.
  Future<void> _fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      _currentUser = UserModel.fromFirestore(doc);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Maps Firebase Auth error codes to Indonesian user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
