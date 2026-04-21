import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/cache_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth      _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore    = FirebaseFirestore.instance;

  UserModel? _user;
  AuthStatus _status        = AuthStatus.idle;
  String     _errorMessage  = '';

  UserModel? get user         => _user;
  AuthStatus get status       => _status;
  String     get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _user != null;
  bool       get isLoading    => _status == AuthStatus.loading;

  Future<void> tryAutoLogin() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;
    _user = UserModel(
      uid:   firebaseUser.uid,
      name:  firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
      email: firebaseUser.email ?? '',
    );
    _status = AuthStatus.success;
    notifyListeners();
    _refreshProfileInBackground(firebaseUser);
  }

  void _refreshProfileInBackground(User firebaseUser) {
    _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get()
        .then((doc) {
      if (doc.exists && doc.data() != null) {
        _user = UserModel.fromJson(doc.data()!);
        notifyListeners();
      } else {
        final newUser = UserModel(
          uid:   firebaseUser.uid,
          name:  firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          email: firebaseUser.email ?? '',
        );
        _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());
      }
      _syncProfileToBackend();
    })
        .catchError((e) {
      if (kDebugMode) print('[Auth] background refresh failed: $e');
    });
  }

  Future<void> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Connection timed out. Check your internet.'),
      );

      _user = UserModel(
        uid:   credential.user!.uid,
        name:  credential.user!.displayName ?? email.split('@')[0],
        email: credential.user!.email ?? email,
      );
      await CacheService.instance.saveLastUid(credential.user!.uid);
      _setStatus(AuthStatus.success);

      _refreshProfileInBackground(credential.user!);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('[FirebaseAuth] ${e.code}: ${e.message}');
      _setError(_friendlyError(e.code));
    } catch (e) {
      if (kDebugMode) print('[Auth] $e');
      _setError(e.toString().contains('timed out')
          ? 'Connection timed out. Check your internet.'
          : 'Something went wrong. Please try again.');
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      final credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
        throw Exception('Connection timed out. Check your internet.'),
      );

      credential.user!.updateDisplayName(name.trim()).catchError((_) {});

      _user = UserModel(
        uid:   credential.user!.uid,
        name:  name.trim(),
        email: email.trim(),
      );
      await CacheService.instance.saveLastUid(credential.user!.uid);
      _setStatus(AuthStatus.success);

      _firestore
          .collection('users')
          .doc(_user!.uid)
          .set(_user!.toJson())
          .catchError((e) {
        if (kDebugMode) print('[Auth] Firestore save failed: $e');
      });
      _syncProfileToBackend();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('[FirebaseAuth] ${e.code}: ${e.message}');
      _setError(_friendlyError(e.code));
    } catch (e) {
      if (kDebugMode) print('[Auth] $e');
      _setError(e.toString().contains('timed out')
          ? 'Connection timed out. Check your internet.'
          : 'Something went wrong. Please try again.');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await CacheService.instance.clearAuth();
    _user         = null;
    _status       = AuthStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _status       = AuthStatus.idle;
    notifyListeners();
  }

  void _syncProfileToBackend() {
    if (_user == null) return;
    ApiService.instance
        .post(ApiEndpoints.profile, {
      'name':  _user!.name,
      'email': _user!.email,
    })
        .catchError((e) {
      if (kDebugMode) print('[Auth] backend sync failed: $e');
    });
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status       = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'unauthorized-domain':
      case 'auth/unauthorized-domain':
        return 'Domain not authorized in Firebase Console.';
      case 'operation-not-allowed':
      case 'auth/operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Console.';
      default:
        return 'Authentication failed (code: $code).';
    }
  }
}