import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:olmeg_connect/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentEntity> createPayment(PaymentEntity payment);

  Future<PaymentEntity> getPayment(String paymentId);

  Future<List<PaymentEntity>> getUserPayments(String userId);

  Future<void> updatePaymentStatus(String paymentId, String status);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;

  PaymentRemoteDataSourceImpl({required this.firestore});

  @override
  Future<PaymentEntity> createPayment(PaymentEntity payment) async {
    try {
      final id = const Uuid().v4();
      final paymentData = {
        'id': id,
        'userId': payment.userId,
        'amount': payment.amount,
        'status': payment.status,
        'productId': payment.productId,
        'paymentMethod': payment.paymentMethod,
        'createdAt': DateTime.now().toIso8601String(),
        'completedAt': null,
      };

      await firestore.collection('payments').doc(id).set(paymentData);

      return PaymentEntity(
        id: id,
        userId: payment.userId,
        amount: payment.amount,
        status: payment.status,
        productId: payment.productId,
        paymentMethod: payment.paymentMethod,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<PaymentEntity> getPayment(String paymentId) async {
    try {
      final doc = await firestore.collection('payments').doc(paymentId).get();

      if (!doc.exists) {
        throw Exception('Payment not found');
      }

      final data = doc.data()!;
      return PaymentEntity(
        id: data['id'] as String,
        userId: data['userId'] as String,
        amount: (data['amount'] as num).toDouble(),
        status: data['status'] as String,
        productId: data['productId'] as String?,
        paymentMethod: data['paymentMethod'] as String,
        createdAt: DateTime.parse(data['createdAt'] as String),
        completedAt: data['completedAt'] != null
            ? DateTime.parse(data['completedAt'] as String)
            : null,
      );
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  @override
  Future<List<PaymentEntity>> getUserPayments(String userId) async {
    try {
      final snapshot = await firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PaymentEntity(
          id: data['id'] as String,
          userId: data['userId'] as String,
          amount: (data['amount'] as num).toDouble(),
          status: data['status'] as String,
          productId: data['productId'] as String?,
          paymentMethod: data['paymentMethod'] as String,
          createdAt: DateTime.parse(data['createdAt'] as String),
          completedAt: data['completedAt'] != null
              ? DateTime.parse(data['completedAt'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user payments: $e');
    }
  }

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await firestore.collection('payments').doc(paymentId).update({
        'status': status,
        'completedAt': status == 'completed' ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }
}
