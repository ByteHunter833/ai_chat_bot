import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nova_ai/features/auth/domain/auth_exception.dart';
import 'package:nova_ai/features/auth/domain/entities/app_user.dart';
import 'package:nova_ai/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return _loadUser(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _loadUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;

      final displayName = name.trim().isEmpty ? 'User' : name.trim();
      await user.updateProfile(displayName: displayName);
      await user.reload();

      await firestore.collection('users').doc(user.uid).set({
        'name': displayName,
        'email': email.trim(),
        'isPro': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return await _loadUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  @override
  Future<void> signOut() => firebaseAuth.signOut();

  @override
  Future<AppUser> grantPro() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.');
    }
    await firestore.collection('users').doc(user.uid).set({
      'isPro': true,
    }, SetOptions(merge: true));
    return _loadUser(user);
  }

  Future<AppUser> _loadUser(User user) async {
    final snapshot = await firestore.collection('users').doc(user.uid).get();
    if (snapshot.exists) {
      return AppUser.fromMap(snapshot.data()!, id: user.uid);
    }
    return AppUser.fromFirebase(user);
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
