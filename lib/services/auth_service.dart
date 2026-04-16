import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/user_model.dart';

/// Authentication service backed by Firebase Auth and Cloud Firestore.
///
/// Registration is exclusively for customers. The role is hardcoded.
/// After registration, a verification email is sent automatically.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn =>
      _auth.currentUser != null &&
      _auth.currentUser!.emailVerified &&
      _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> initializeAuth() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.emailVerified) {
      await _fetchUserProfile(firebaseUser.uid);
    }
  }

  /// Registers a new customer, saves profile to Firestore, and sends
  /// a verification email. Does NOT sign out so the verification screen
  /// can call reload/resend on the current user.
  /// Returns `null` on success, or a user-friendly error message.
  Future<String?> registerUser({
    required String nama,
    required String email,
    required String password,
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
        role: UserRole.customer,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userModel.toFirestore());

      await credential.user!.sendEmailVerification();

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

  /// Authenticates a user. If email is not verified, returns a special
  /// result string 'email-not-verified' so the UI can redirect.
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

      if (!credential.user!.emailVerified) {
        _setLoading(false);
        return 'email-not-verified';
      }

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

  /// Reloads the current Firebase user and checks emailVerified status.
  /// On success, fetches Firestore profile and returns `true`.
  Future<bool> checkEmailVerified() async {
    _setLoading(true);
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        await _fetchUserProfile(user.uid);
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (_) {
      _setLoading(false);
      return false;
    }
  }

  /// Resends the verification email to the current user.
  /// Returns `null` on success, or a user-friendly error message.
  Future<String?> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (_) {
      return 'Gagal mengirim ulang email. Coba lagi nanti.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

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
