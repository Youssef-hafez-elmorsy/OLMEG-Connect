import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    super.role,
    super.accountType,
    super.merchantVerificationStatus,
    required super.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isAdminFlag = data['isAdmin'] == true;
    final role = (data['role'] as String?)?.trim().toLowerCase();
    final accountTypeValue =
        (data['accountType'] as String?)?.trim().toLowerCase();
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      role: role?.isNotEmpty == true ? role! : (isAdminFlag ? 'admin' : 'user'),
      accountType: accountTypeValue == 'merchant'
          ? AccountType.merchant
          : AccountType.regular,
      merchantVerificationStatus: merchantVerificationStatusFromString(
        data['merchantVerificationStatus'] as String?,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'role': role,
        'isAdmin': isAdmin,
        'accountType': accountType.name,
        'merchantVerificationStatus': merchantVerificationStatusToString(
          merchantVerificationStatus,
        ),
        'isMerchant': isMerchant,
        'isApprovedMerchant': isApprovedMerchant,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        email: entity.email,
        name: entity.name,
        photoUrl: entity.photoUrl,
        role: entity.role,
        accountType: entity.accountType,
        merchantVerificationStatus: entity.merchantVerificationStatus,
        createdAt: entity.createdAt,
      );
}
