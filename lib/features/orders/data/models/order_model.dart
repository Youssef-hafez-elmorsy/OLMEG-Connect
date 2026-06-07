import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/orders/domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.productId,
    required super.sellerId,
    required super.titleSnapshot,
    super.imageUrlSnapshot,
    super.selectedVariantSnapshot,
    required super.quantity,
    required super.unitPrice,
    required super.lineTotal,
    super.fulfillmentStatus,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      titleSnapshot: map['titleSnapshot'] as String? ?? '',
      imageUrlSnapshot: map['imageUrlSnapshot'] as String?,
      selectedVariantSnapshot: map['selectedVariantSnapshot'] is Map
          ? Map<String, dynamic>.from(map['selectedVariantSnapshot'] as Map)
          : null,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0,
      fulfillmentStatus: fulfillmentStatusFromString(
        map['fulfillmentStatus'] as String?,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'titleSnapshot': titleSnapshot,
      'imageUrlSnapshot': imageUrlSnapshot,
      'selectedVariantSnapshot': selectedVariantSnapshot,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'fulfillmentStatus': fulfillmentStatusToString(fulfillmentStatus),
    };
  }
}

class AddressSnapshotModel extends AddressSnapshot {
  const AddressSnapshotModel({
    required super.fullName,
    required super.phone,
    required super.line1,
    super.line2,
    required super.city,
    super.region,
    super.postalCode,
    super.country,
  });

  factory AddressSnapshotModel.fromEntity(AddressSnapshot address) {
    return AddressSnapshotModel(
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

  factory AddressSnapshotModel.fromMap(Map<String, dynamic> map) {
    return AddressSnapshotModel(
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      line1: map['line1'] as String? ?? '',
      line2: map['line2'] as String? ?? '',
      city: map['city'] as String? ?? '',
      region: map['region'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      country: map['country'] as String? ?? 'Egypt',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'region': region,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

class PaymentSummaryModel extends PaymentSummary {
  const PaymentSummaryModel({
    required super.provider,
    super.providerPaymentId,
    super.status,
    super.paidAt,
    super.failureReason,
  });

  factory PaymentSummaryModel.fromEntity(PaymentSummary payment) {
    return PaymentSummaryModel(
      provider: payment.provider,
      providerPaymentId: payment.providerPaymentId,
      status: payment.status,
      paidAt: payment.paidAt,
      failureReason: payment.failureReason,
    );
  }

  factory PaymentSummaryModel.fromMap(Map<String, dynamic> map) {
    return PaymentSummaryModel(
      provider: map['provider'] as String? ?? 'paymob',
      providerPaymentId: map['providerPaymentId'] as String?,
      status: paymentSummaryStatusFromString(map['status'] as String?),
      paidAt: _readDate(map['paidAt']),
      failureReason: map['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'providerPaymentId': providerPaymentId,
      'status': paymentSummaryStatusToString(status),
      'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
      'failureReason': failureReason,
    };
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.buyerId,
    required super.sellerIds,
    required super.items,
    required super.shippingAddress,
    required super.payment,
    required super.subtotal,
    super.shippingFee,
    super.tax,
    super.discount,
    required super.total,
    super.currency,
    super.status,
    required super.checkoutFingerprint,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromEntity(OrderEntity order) {
    return OrderModel(
      id: order.id,
      buyerId: order.buyerId,
      sellerIds: order.sellerIds,
      items: order.items,
      shippingAddress: order.shippingAddress,
      payment: order.payment,
      subtotal: order.subtotal,
      shippingFee: order.shippingFee,
      tax: order.tax,
      discount: order.discount,
      total: order.total,
      currency: order.currency,
      status: order.status,
      checkoutFingerprint: order.checkoutFingerprint,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return OrderModel.fromMap({...data, 'id': doc.id});
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => OrderItemModel.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <OrderItemModel>[];

    return OrderModel(
      id: map['id'] as String? ?? '',
      buyerId: map['buyerId'] as String? ?? '',
      sellerIds: List<String>.from(map['sellerIds'] as List? ?? const []),
      items: items,
      shippingAddress: AddressSnapshotModel.fromMap(
        Map<String, dynamic>.from(
          map['shippingAddress'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      payment: PaymentSummaryModel.fromMap(
        Map<String, dynamic>.from(
          map['payment'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'EGP',
      status: orderStatusFromString(map['status'] as String?),
      checkoutFingerprint: map['checkoutFingerprint'] as String? ?? '',
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'sellerIds': sellerIds,
      'items': items.map(_itemToMap).toList(),
      'shippingAddress':
          AddressSnapshotModel.fromEntity(shippingAddress).toMap(),
      'payment': PaymentSummaryModel.fromEntity(payment).toMap(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'currency': currency,
      'status': orderStatusToString(status),
      'checkoutFingerprint': checkoutFingerprint,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> _itemToMap(OrderItemEntity item) {
    return OrderItemModel(
      productId: item.productId,
      sellerId: item.sellerId,
      titleSnapshot: item.titleSnapshot,
      imageUrlSnapshot: item.imageUrlSnapshot,
      selectedVariantSnapshot: item.selectedVariantSnapshot,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      lineTotal: item.lineTotal,
      fulfillmentStatus: item.fulfillmentStatus,
    ).toMap();
  }
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
