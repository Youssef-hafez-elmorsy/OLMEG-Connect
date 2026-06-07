import 'package:equatable/equatable.dart';

enum AccountType {
  regular,
  merchant,
}

enum MerchantVerificationStatus {
  none,
  draft,
  submitted,
  approved,
  rejected,
  suspended,
}

class MerchantVerificationEntity extends Equatable {
  final String userId;
  final String legalBusinessName;
  final String taxId;
  final String businessAddress;
  final String businessPhone;
  final String contactEmail;
  final MerchantVerificationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantVerificationEntity({
    required this.userId,
    required this.legalBusinessName,
    required this.taxId,
    required this.businessAddress,
    required this.businessPhone,
    required this.contactEmail,
    this.status = MerchantVerificationStatus.submitted,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == MerchantVerificationStatus.approved;

  @override
  List<Object?> get props => [
        userId,
        legalBusinessName,
        taxId,
        businessAddress,
        businessPhone,
        contactEmail,
        status,
        createdAt,
        updatedAt,
      ];
}

MerchantVerificationStatus merchantVerificationStatusFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'draft':
      return MerchantVerificationStatus.draft;
    case 'submitted':
      return MerchantVerificationStatus.submitted;
    case 'approved':
      return MerchantVerificationStatus.approved;
    case 'rejected':
      return MerchantVerificationStatus.rejected;
    case 'suspended':
      return MerchantVerificationStatus.suspended;
    default:
      return MerchantVerificationStatus.none;
  }
}

String merchantVerificationStatusToString(
  MerchantVerificationStatus status,
) {
  return status.name;
}
