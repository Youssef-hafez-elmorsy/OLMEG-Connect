import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';

bool isDeliveryEligible({
  required bool isHandicraft,
  required MerchantVerificationStatus merchantStatus,
}) {
  return isHandicraft && merchantStatus == MerchantVerificationStatus.approved;
}
