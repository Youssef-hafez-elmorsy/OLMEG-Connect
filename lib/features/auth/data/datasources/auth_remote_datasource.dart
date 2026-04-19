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
        final doc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
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
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return UserModel(id: user.uid, email: user.email ?? '', name: user.displayName ?? '', createdAt: DateTime.now());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    }
  }

  @override
  Future<UserModel> signUp({required String email, required String password, required String name}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      await user.updateDisplayName(name);
      final model = UserModel(id: user.uid, email: email, name: name, createdAt: DateTime.now());
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(model.toFirestore());
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
