import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/payments/domain/entities/payment_entity.dart';
import 'package:olmeg_connect/features/payments/domain/repositories/payment_repository.dart';
import 'package:olmeg_connect/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:olmeg_connect/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
  );
});

final userPaymentsProvider = FutureProvider.family<List<PaymentEntity>, String>(
  (ref, userId) async {
    final repository = ref.watch(paymentRepositoryProvider);
    final result = await repository.getUserPayments(userId);
    return result.fold(
      (failure) => [],
      (payments) => payments,
    );
  },
);

final createPaymentProvider = FutureProvider.family<PaymentEntity, ({double amount, String productId, int quantity})>(
  (ref, params) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) throw Exception('User not authenticated');

    final payment = PaymentEntity(
      id: const Uuid().v4(),
      userId: user.id,
      amount: params.amount,
      status: 'pending',
      productId: params.productId,
      paymentMethod: 'paypal',
      createdAt: DateTime.now(),
      completedAt: null,
    );

    final repository = ref.watch(paymentRepositoryProvider);
    final result = await repository.createPayment(payment);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (payment) => payment,
    );
  },
);

final updatePaymentStatusProvider = FutureProvider.family<void, (String, String)>(
  (ref, params) async {
    final repository = ref.watch(paymentRepositoryProvider);
    final result = await repository.updatePaymentStatus(params.$1, params.$2);
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => null,
    );
  },
);
