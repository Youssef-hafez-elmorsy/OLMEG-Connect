import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
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

final signInUseCaseProvider = Provider((ref) => SignInUseCase(ref.watch(authRepositoryProvider)));
final signUpUseCaseProvider = Provider((ref) => SignUpUseCase(ref.watch(authRepositoryProvider)));
final signOutUseCaseProvider = Provider((ref) => SignOutUseCase(ref.watch(authRepositoryProvider)));

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthNotifier extends Notifier<AsyncValue<UserEntity?>> {
  @override
  AsyncValue<UserEntity?> build() => const AsyncValue.data(null);

  late final SignInUseCase _signIn = ref.watch(signInUseCaseProvider);
  late final SignUpUseCase _signUp = ref.watch(signUpUseCaseProvider);
  late final SignOutUseCase _signOut = ref.watch(signOutUseCaseProvider);

  Future<String?> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await _signIn(email: email, password: password);
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<String?> signUp({required String email, required String password, required String name}) async {
    state = const AsyncValue.loading();
    final result = await _signUp(email: email, password: password, name: name);
    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<void> signOut() async {
    await _signOut();
    state = const AsyncValue.data(null);
    ref.invalidate(authStateProvider);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>(() {
  return AuthNotifier();
});