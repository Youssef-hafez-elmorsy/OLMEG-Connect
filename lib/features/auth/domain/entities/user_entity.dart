import 'package:equatable/equatable.dart';
import 'merchant_verification_entity.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role;
  final AccountType accountType;
  final MerchantVerificationStatus merchantVerificationStatus;
  final DateTime createdAt;

  bool get isAdmin => role == 'admin';
  bool get isMerchant => accountType == AccountType.merchant;
  bool get isApprovedMerchant =>
      isMerchant &&
      merchantVerificationStatus == MerchantVerificationStatus.approved;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'user',
    this.accountType = AccountType.regular,
    this.merchantVerificationStatus = MerchantVerificationStatus.none,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        role,
        accountType,
        merchantVerificationStatus,
        createdAt,
      ];
}
