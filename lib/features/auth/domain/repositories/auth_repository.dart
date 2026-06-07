import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/merchant_verification_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<Either<Failure, UserEntity>> signIn(
      {required String email, required String password});
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    AccountType accountType,
    MerchantVerificationEntity? merchantVerification,
  });
  Future<Either<Failure, void>> signOut();
  UserEntity? get currentUser;
}
