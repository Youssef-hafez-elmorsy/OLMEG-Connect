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
      final user = await _dataSource.signIn(email: email, password: password);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(AuthFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({required String email, required String password, required String name}) async {
    try {
      final user = await _dataSource.signUp(email: email, password: password, name: name);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(AuthFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (_) {
      return const Left(AuthFailure('Failed to sign out.'));
    }
  }
}
