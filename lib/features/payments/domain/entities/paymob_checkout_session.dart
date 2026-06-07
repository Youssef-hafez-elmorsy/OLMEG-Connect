import 'package:equatable/equatable.dart';

class PaymobCheckoutSession extends Equatable {
  final String orderId;
  final String paymentId;
  final String clientSecret;
  final String publicKey;
  final String checkoutUrl;
  final String status;

  const PaymobCheckoutSession({
    required this.orderId,
    required this.paymentId,
    required this.clientSecret,
    required this.publicKey,
    required this.checkoutUrl,
    required this.status,
  });

  factory PaymobCheckoutSession.fromMap(Map<String, dynamic> map) {
    return PaymobCheckoutSession(
      orderId: map['orderId'] as String? ?? '',
      paymentId: map['paymentId'] as String? ?? '',
      clientSecret: map['clientSecret'] as String? ?? '',
      publicKey: map['publicKey'] as String? ?? '',
      checkoutUrl: map['checkoutUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        paymentId,
        clientSecret,
        publicKey,
        checkoutUrl,
        status,
      ];
}
