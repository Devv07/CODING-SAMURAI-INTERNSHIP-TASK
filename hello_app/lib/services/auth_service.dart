// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());

      final model = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        isOnline: true,
      );

      await _db
          .ref('${AppConstants.pathUsers}/${user.uid}')
          .set(model.toMap());

      await setupPresence(user.uid);
      return model;
    } on FirebaseAuthException catch (e) {
      throw _message(e);
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      await setupPresence(uid);

      final snap = await _db.ref('${AppConstants.pathUsers}/$uid').get();
      if (!snap.exists) throw 'User data not found';
      return UserModel.fromMap(snap.value as Map<dynamic, dynamic>);
    } on FirebaseAuthException catch (e) {
      throw _message(e);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final uid = currentUid;
    if (uid != null) {
      await _db.ref('${AppConstants.pathUsers}/$uid').update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    await _auth.signOut();
  }

  // ─── Reset Password ───────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _message(e);
    }
  }

  // ─── Get Current User ─────────────────────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) return null;
    final snap = await _db.ref('${AppConstants.pathUsers}/$uid').get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.value as Map<dynamic, dynamic>);
  }

  // ─── Presence — call this on app resume too ───────────────────────────────

  Future<void> setupPresence(String uid) async {
    final userRef = _db.ref('${AppConstants.pathUsers}/$uid');

    // Set online immediately
    await userRef.update({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    });

    // ✅ Register onDisconnect — fires when socket closes (app killed/network lost)
    await userRef.child('isOnline').onDisconnect().set(false);
    await userRef.child('lastSeen').onDisconnect().set(ServerValue.timestamp);
  }

  // ─── Error Messages ───────────────────────────────────────────────────────

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}