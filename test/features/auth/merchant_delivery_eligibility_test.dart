import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_connect/features/auth/domain/entities/merchant_verification_entity.dart';
import 'package:olmeg_connect/features/products/domain/services/delivery_eligibility.dart';

void main() {
  group('merchant delivery eligibility', () {
    test('allows delivery only for approved merchants with handcraft products',
        () {
      expect(
        isDeliveryEligible(
          isHandicraft: true,
          merchantStatus: MerchantVerificationStatus.approved,
        ),
        isTrue,
      );
    });

    test('rejects non-handcraft products even for approved merchants', () {
      expect(
        isDeliveryEligible(
          isHandicraft: false,
          merchantStatus: MerchantVerificationStatus.approved,
        ),
        isFalse,
      );
    });

    test('rejects handcraft products from unapproved merchants', () {
      expect(
        isDeliveryEligible(
          isHandicraft: true,
          merchantStatus: MerchantVerificationStatus.submitted,
        ),
        isFalse,
      );
    });
  });
}
