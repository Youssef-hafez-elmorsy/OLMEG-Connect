import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final String? productId;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PaymentEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    this.productId,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        status,
        productId,
        paymentMethod,
        createdAt,
        completedAt,
      ];
}
