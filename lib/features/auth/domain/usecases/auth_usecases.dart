import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;
  SignInUseCase(this.repository);
  Future<Either<Failure, UserEntity>> call({required String email, required String password}) =>
      repository.signIn(email: email, password: password);
}

class SignUpUseCase {
  final AuthRepository repository;
  SignUpUseCase(this.repository);
  Future<Either<Failure, UserEntity>> call({required String email, required String password, required String name}) =>
      repository.signUp(email: email, password: password, name: name);
}

class SignOutUseCase {
  final AuthRepository repository;
  SignOutUseCase(this.repository);
  Future<Either<Failure, void>> call() => repository.signOut();
}
