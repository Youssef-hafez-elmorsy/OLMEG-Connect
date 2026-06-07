import 'package:equatable/equatable.dart';
import 'package:olmeg_connect/features/profile/domain/entities/address_entity.dart';

enum OrderStatus {
  pendingPayment,
  paid,
  preparing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

enum OrderItemFulfillmentStatus {
  pending,
  preparing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

enum PaymentSummaryStatus {
  notStarted,
  pending,
  authorized,
  paid,
  failed,
  refunded,
}

String orderStatusToString(OrderStatus status) => status.name;

OrderStatus orderStatusFromString(String? value) {
  return OrderStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => OrderStatus.pendingPayment,
  );
}

String fulfillmentStatusToString(OrderItemFulfillmentStatus status) =>
    status.name;

OrderItemFulfillmentStatus fulfillmentStatusFromString(String? value) {
  return OrderItemFulfillmentStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => OrderItemFulfillmentStatus.pending,
  );
}

String paymentSummaryStatusToString(PaymentSummaryStatus status) => status.name;

PaymentSummaryStatus paymentSummaryStatusFromString(String? value) {
  return PaymentSummaryStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => PaymentSummaryStatus.notStarted,
  );
}

OrderStatus orderStatusForPayment(PaymentSummaryStatus status) {
  switch (status) {
    case PaymentSummaryStatus.paid:
    case PaymentSummaryStatus.authorized:
      return OrderStatus.paid;
    case PaymentSummaryStatus.refunded:
      return OrderStatus.refunded;
    case PaymentSummaryStatus.failed:
    case PaymentSummaryStatus.notStarted:
    case PaymentSummaryStatus.pending:
      return OrderStatus.pendingPayment;
  }
}

bool isAllowedOrderStatusTransition(OrderStatus from, OrderStatus to) {
  if (from == to) return true;

  switch (from) {
    case OrderStatus.pendingPayment:
      return to == OrderStatus.paid || to == OrderStatus.cancelled;
    case OrderStatus.paid:
      return to == OrderStatus.preparing ||
          to == OrderStatus.cancelled ||
          to == OrderStatus.refunded;
    case OrderStatus.preparing:
      return to == OrderStatus.shipped ||
          to == OrderStatus.cancelled ||
          to == OrderStatus.refunded;
    case OrderStatus.shipped:
      return to == OrderStatus.delivered || to == OrderStatus.refunded;
    case OrderStatus.delivered:
      return to == OrderStatus.refunded;
    case OrderStatus.cancelled:
    case OrderStatus.refunded:
      return false;
  }
}

class AddressSnapshot extends Equatable {
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String region;
  final String postalCode;
  final String country;

  const AddressSnapshot({
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    this.region = '',
    this.postalCode = '',
    this.country = 'Egypt',
  });

  factory AddressSnapshot.fromAddress(AddressEntity address) {
    return AddressSnapshot(
      fullName: address.fullName,
      phone: address.phone,
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      region: address.region,
      postalCode: address.postalCode,
      country: address.country,
    );
  }

  String get formatted {
    return [
      line1,
      if (line2.isNotEmpty) line2,
      city,
      if (region.isNotEmpty) region,
      if (postalCode.isNotEmpty) postalCode,
      country,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  @override
  List<Object?> get props => [
        fullName,
        phone,
        line1,
        line2,
        city,
        region,
        postalCode,
        country,
      ];
}

class PaymentSummary extends Equatable {
  final String provider;
  final String? providerPaymentId;
  final PaymentSummaryStatus status;
  final DateTime? paidAt;
  final String? failureReason;

  const PaymentSummary({
    required this.provider,
    this.providerPaymentId,
    this.status = PaymentSummaryStatus.notStarted,
    this.paidAt,
    this.failureReason,
  });

  PaymentSummary copyWith({
    String? provider,
    String? providerPaymentId,
    PaymentSummaryStatus? status,
    DateTime? paidAt,
    String? failureReason,
  }) {
    return PaymentSummary(
      provider: provider ?? this.provider,
      providerPaymentId: providerPaymentId ?? this.providerPaymentId,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => [
        provider,
        providerPaymentId,
        status,
        paidAt,
        failureReason,
      ];
}

class OrderItemEntity extends Equatable {
  final String productId;
  final String sellerId;
  final String titleSnapshot;
  final String? imageUrlSnapshot;
  final Map<String, dynamic>? selectedVariantSnapshot;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final OrderItemFulfillmentStatus fulfillmentStatus;

  const OrderItemEntity({
    required this.productId,
    required this.sellerId,
    required this.titleSnapshot,
    this.imageUrlSnapshot,
    this.selectedVariantSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.fulfillmentStatus = OrderItemFulfillmentStatus.pending,
  });

  @override
  List<Object?> get props => [
        productId,
        sellerId,
        titleSnapshot,
        imageUrlSnapshot,
        selectedVariantSnapshot,
        quantity,
        unitPrice,
        lineTotal,
        fulfillmentStatus,
      ];
}

class OrderEntity extends Equatable {
  final String id;
  final String buyerId;
  final List<String> sellerIds;
  final List<OrderItemEntity> items;
  final AddressSnapshot shippingAddress;
  final PaymentSummary payment;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final double discount;
  final double total;
  final String currency;
  final OrderStatus status;
  final String checkoutFingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderEntity({
    required this.id,
    required this.buyerId,
    required this.sellerIds,
    required this.items,
    required this.shippingAddress,
    required this.payment,
    required this.subtotal,
    this.shippingFee = 0,
    this.tax = 0,
    this.discount = 0,
    required this.total,
    this.currency = 'EGP',
    this.status = OrderStatus.pendingPayment,
    required this.checkoutFingerprint,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive {
    return status != OrderStatus.cancelled &&
        status != OrderStatus.delivered &&
        status != OrderStatus.refunded;
  }

  OrderEntity copyWith({
    String? id,
    String? buyerId,
    List<String>? sellerIds,
    List<OrderItemEntity>? items,
    AddressSnapshot? shippingAddress,
    PaymentSummary? payment,
    double? subtotal,
    double? shippingFee,
    double? tax,
    double? discount,
    double? total,
    String? currency,
    OrderStatus? status,
    String? checkoutFingerprint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerIds: sellerIds ?? this.sellerIds,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      payment: payment ?? this.payment,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      checkoutFingerprint: checkoutFingerprint ?? this.checkoutFingerprint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        buyerId,
        sellerIds,
        items,
        shippingAddress,
        payment,
        subtotal,
        shippingFee,
        tax,
        discount,
        total,
        currency,
        status,
        checkoutFingerprint,
        createdAt,
        updatedAt,
      ];
}
