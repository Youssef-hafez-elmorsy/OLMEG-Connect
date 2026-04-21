import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);

  @override
  Stream<UserEntity?> get authStateChanges => _dataSource.authStateChanges;

  @override
  UserEntity? get currentUser => _dataSource.currentUser;

  @override
  Future<Either<Failure, UserEntity>> signIn({required String email, required String password}) async {
    try {
      print('[Repo] Sign in attempt for: $email');
      final user = await _dataSource.signIn(email: email, password: password);
      print('[Repo] Sign in successful');
      return Right(user);
    } on AuthFailure catch (e) {
      print('[Repo] AuthFailure: ${e.message}');
      return Left(e);
    } catch (e) {
      print('[Repo] Unexpected error: $e');
      final failure = AuthFailure('Sign in failed: $e');
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({required String email, required String password, required String name}) async {
    try {
      print('[Repo] Sign up attempt for: $email, name: $name');
      final user = await _dataSource.signUp(email: email, password: password, name: name);
      print('[Repo] Sign up successful');
      return Right(user);
    } on AuthFailure catch (e) {
      print('[Repo] AuthFailure: ${e.message}');
      return Left(e);
    } catch (e) {
      print('[Repo] Unexpected error: $e');
      final failure = AuthFailure('Sign up failed: $e');
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AuthFailure('Failed to sign out: $e'));
    }
  }
}