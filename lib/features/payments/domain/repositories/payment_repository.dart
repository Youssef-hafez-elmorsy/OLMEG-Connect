import 'package:dartz/dartz.dart';
import 'package:olmeg_connect/core/errors/failures.dart';
import 'package:olmeg_connect/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, PaymentEntity>> createPayment(PaymentEntity payment);

  Future<Either<Failure, PaymentEntity>> getPayment(String paymentId);

  Future<Either<Failure, List<PaymentEntity>>> getUserPayments(String userId);

  Future<Either<Failure, void>> updatePaymentStatus(
    String paymentId,
    String status,
  );
}
