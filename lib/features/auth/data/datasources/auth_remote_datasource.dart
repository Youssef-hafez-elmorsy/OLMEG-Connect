import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({required String email, required String password, required String name});
  Future<void> signOut();
  UserModel? get currentUser;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          final doc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc);
        } catch (e) {
          return null;
        }
      });

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL,
      role: 'user',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;

      if (user == null) {
        throw const AuthFailure('No user returned after sign in.');
      }

      final doc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: 'user',
        createdAt: DateTime.now(),
      );

    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure('Firebase error: ${e.message}');
    } catch (e) {
      throw AuthFailure('Error: $e');
    }
  }

  @override
  Future<UserModel> signUp({required String email, required String password, required String name}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;

      if (user == null) {
        throw const AuthFailure('No user returned after sign up.');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create user document in Firestore
      final model = UserModel(
        id: user.uid,
        email: email,
        name: name,
        role: 'user',
        createdAt: DateTime.now(),
      );
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(model.toFirestore());

      return model;

    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure('Firebase error: ${e.message}');
    } catch (e) {
      throw AuthFailure('Error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthFailure('Failed to sign out: $e');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'internal-error':
        return 'Internal error. Please try again.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      default:
        return 'Error: $code';
    }
  }
}
