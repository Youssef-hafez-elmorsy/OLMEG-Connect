import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';

class MerchantVerificationModel extends MerchantVerificationEntity {
  const MerchantVerificationModel({
    required super.userId,
    required super.legalBusinessName,
    required super.taxId,
    required super.businessAddress,
    required super.businessPhone,
    required super.contactEmail,
    super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MerchantVerificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantVerificationModel(
      userId: doc.id,
      legalBusinessName: data['legalBusinessName'] as String? ?? '',
      taxId: data['taxId'] as String? ?? '',
      businessAddress: data['businessAddress'] as String? ?? '',
      businessPhone: data['businessPhone'] as String? ?? '',
      contactEmail: data['contactEmail'] as String? ?? '',
      status: merchantVerificationStatusFromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'legalBusinessName': legalBusinessName,
      'taxId': taxId,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'contactEmail': contactEmail,
      'status': merchantVerificationStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MerchantVerificationModel.fromEntity(
    MerchantVerificationEntity entity,
  ) {
    return MerchantVerificationModel(
      userId: entity.userId,
      legalBusinessName: entity.legalBusinessName,
      taxId: entity.taxId,
      businessAddress: entity.businessAddress,
      businessPhone: entity.businessPhone,
      contactEmail: entity.contactEmail,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
