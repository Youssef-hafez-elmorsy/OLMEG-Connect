import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_admin_web/core/firestore/admin_capped_query.dart';

void main() {
  group('admin capped query guardrails', () {
    test('uses default page size when no valid limit is requested', () {
      expect(cappedAdminLimit(), adminDefaultPageSize);
      expect(cappedAdminLimit(0), adminDefaultPageSize);
      expect(cappedAdminLimit(-10), adminDefaultPageSize);
    });

    test('caps large table requests at the admin maximum', () {
      expect(cappedAdminLimit(1), 1);
      expect(cappedAdminLimit(adminMaxPageSize), adminMaxPageSize);
      expect(cappedAdminLimit(adminMaxPageSize + 1), adminMaxPageSize);
      expect(cappedAdminLimit(5000), adminMaxPageSize);
    });
  });
}
