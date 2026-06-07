import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/seller/domain/entities/seller_profile_entity.dart';

final sellerProfileProvider =
    StreamProvider.family<SellerProfileEntity?, String>((ref, sellerId) {
  return FirebaseFirestore.instance
      .collection('sellerProfiles')
      .doc(sellerId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = doc.data() ?? const <String, dynamic>{};
    return SellerProfileEntity(
      userId: sellerId,
      displayName: data['displayName'] as String? ?? '',
      storeName: data['storeName'] as String? ?? 'Seller store',
      ratingAverage: (data['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      verificationStatus: data['verificationStatus'] as String? ?? 'unverified',
      returnPolicy: data['returnPolicy'] as String? ?? '',
      shippingMethods: List<String>.from(
        data['shippingMethods'] as List? ?? const [],
      ),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(data['updatedAt']) ?? DateTime.now(),
    );
  });
});

final sellerAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.isApprovedMerchant == true || user?.isAdmin == true;
});

Future<void> saveSellerProfile({
  required String userId,
  required String displayName,
  required String storeName,
  required String returnPolicy,
  required List<String> shippingMethods,
  required String verificationStatus,
}) async {
  await FirebaseFirestore.instance
      .collection('sellerProfiles')
      .doc(userId)
      .set({
    'displayName': displayName,
    'storeName': storeName,
    'returnPolicy': returnPolicy,
    'shippingMethods': shippingMethods,
    'verificationStatus': verificationStatus,
    'updatedAt': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
