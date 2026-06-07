import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:olmeg_connect/features/payments/domain/entities/paymob_checkout_session.dart';
import 'package:olmeg_connect/features/payments/domain/entities/payment_entity.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentEntity> createPayment(PaymentEntity payment);

  Future<PaymentEntity> getPayment(String paymentId);

  Future<List<PaymentEntity>> getUserPayments(String userId);

  Future<void> updatePaymentStatus(String paymentId, String status);

  Future<PaymobCheckoutSession> startPaymobCheckout(String orderId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  PaymentRemoteDataSourceImpl({
    required this.firestore,
    required this.functions,
  });

  @override
  Future<PaymentEntity> createPayment(PaymentEntity payment) async {
    throw UnsupportedError(
      'Direct payment writes are disabled. Use startPaymobCheckout instead.',
    );
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
        createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
        completedAt: _readDate(data['completedAt']),
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
          .limit(25)
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
          createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
          completedAt: _readDate(data['completedAt']),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user payments: $e');
    }
  }

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    throw UnsupportedError(
      'Direct payment status updates are disabled. Paymob webhooks update payment status.',
    );
  }

  @override
  Future<PaymobCheckoutSession> startPaymobCheckout(String orderId) async {
    try {
      final callable = functions.httpsCallable('createPaymobPayment');
      final response = await callable.call<Map<String, dynamic>>({
        'orderId': orderId,
      });
      return PaymobCheckoutSession.fromMap(
        Map<String, dynamic>.from(response.data),
      );
    } catch (e) {
      throw Exception('Failed to start Paymob checkout: $e');
    }
  }
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
