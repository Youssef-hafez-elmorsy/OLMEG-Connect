import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/merchant_verification_entity.dart';
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
  Future<Either<Failure, UserEntity>> signIn(
      {required String email, required String password}) async {
    try {
      final user = await _dataSource.signIn(email: email, password: password);
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
      final failure = AuthFailure('Sign in failed: $e');
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    AccountType accountType = AccountType.regular,
    MerchantVerificationEntity? merchantVerification,
  }) async {
    try {
      final user = await _dataSource.signUp(
        email: email,
        password: password,
        name: name,
        accountType: accountType,
        merchantVerification: merchantVerification,
      );
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } catch (e) {
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
