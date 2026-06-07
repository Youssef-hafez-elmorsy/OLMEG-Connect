import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/services/notification_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/merchant_verification_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider =
    Provider((ref) => SignInUseCase(ref.watch(authRepositoryProvider)));
final signUpUseCaseProvider =
    Provider((ref) => SignUpUseCase(ref.watch(authRepositoryProvider)));
final signOutUseCaseProvider =
    Provider((ref) => SignOutUseCase(ref.watch(authRepositoryProvider)));

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthNotifier extends Notifier<AsyncValue<UserEntity?>> {
  @override
  AsyncValue<UserEntity?> build() => const AsyncValue.data(null);

  late final SignInUseCase _signIn = ref.watch(signInUseCaseProvider);
  late final SignUpUseCase _signUp = ref.watch(signUpUseCaseProvider);
  late final SignOutUseCase _signOut = ref.watch(signOutUseCaseProvider);

  Future<String?> signIn(
      {required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await _signIn(email: email, password: password);
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        if (user.id.isNotEmpty) {
          NotificationService.instance.saveTokenForUser(user.id);
          _sendWelcomeMessage(user.id, user.name, false);
        }
        return null;
      },
    );
  }

  Future<String?> signUp(
      {required String email,
      required String password,
      required String name,
      AccountType accountType = AccountType.regular,
      MerchantVerificationEntity? merchantVerification}) async {
    state = const AsyncValue.loading();
    final result = await _signUp(
      email: email,
      password: password,
      name: name,
      accountType: accountType,
      merchantVerification: merchantVerification,
    );
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        if (user.id.isNotEmpty) {
          NotificationService.instance.saveTokenForUser(user.id);
          _sendWelcomeMessage(user.id, user.name, true);
        }
        return null;
      },
    );
  }

  Future<void> signOut() async {
    await _signOut();
    state = const AsyncValue.data(null);
    ref.invalidate(authStateProvider);
  }

  Future<void> _sendWelcomeMessage(
      String userId, String userName, bool isNewUser) async {
    try {
      final fs = FirebaseFirestore.instance;
      final today = _todayKey();
      final userRef = fs.collection('users').doc(userId);
      if (!isNewUser) {
        final userDoc = await userRef.get();
        if (userDoc.data()?['lastWelcomeBackDate'] == today) {
          await userRef.set({
            'dailySignInCount.$today': FieldValue.increment(1),
            'lastSignInAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return;
        }
      }
      final welcomeMessage = isNewUser
          ? 'Welcome to Olmeg Connect, $userName!\n\nEverything you need in one place. You can:\n- Browse amazing deals\n- List your products for sale\n- Connect with sellers in chat\n- Save favorites\n\nHappy shopping!'
          : 'Welcome back, $userName!\n\nEverything you need in one place. Start browsing or check out new listings!';

      await fs.collection('notifications').doc().set({
        'userId': userId,
        'title': isNewUser ? 'Welcome to Olmeg Connect!' : 'Welcome Back!',
        'body': welcomeMessage,
        'type': 'welcome',
        'read': false,
        'createdAt': DateTime.now(),
      });
      await userRef.set({
        if (!isNewUser) 'lastWelcomeBackDate': today,
        'dailySignInCount.$today': FieldValue.increment(1),
        'lastSignInAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(() {
  return AuthNotifier();
});
