import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/payments/domain/entities/payment_entity.dart';
import 'package:olmeg_connect/features/payments/domain/repositories/payment_repository.dart';
import 'package:olmeg_connect/features/payments/data/datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PaymentEntity>> createPayment(
    PaymentEntity payment,
  ) async {
    try {
      final result = await remoteDataSource.createPayment(payment);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentEntity>> getPayment(String paymentId) async {
    try {
      final result = await remoteDataSource.getPayment(paymentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentEntity>>> getUserPayments(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getUserPayments(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePaymentStatus(
    String paymentId,
    String status,
  ) async {
    try {
      await remoteDataSource.updatePaymentStatus(paymentId, status);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
