import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olmeg_admin_web/core/rbac/admin_access.dart';
import 'package:olmeg_admin_web/core/rbac/admin_roles.dart';

void main() {
  group('admin v2 route smoke coverage', () {
    test('all v2 route contracts are registered with role guards', () {
      final expectedRoutes = [
        '/search',
        '/ai-assistant',
        '/users/:userId',
        '/merchants/:merchantId',
        '/catalog/products',
        '/catalog/products/:productId',
        '/catalog/categories',
        '/moderation/reviews',
        '/reports/:reportId',
        '/orders',
        '/orders/:orderId',
        '/refunds',
        '/payments',
        '/payments/paymob',
        '/support/tickets',
        '/marketing/promotions',
        '/risk',
        '/analytics',
        '/staff',
        '/settings',
      ];

      for (final route in expectedRoutes) {
        expect(routeForPath(route), isNotNull, reason: '$route missing');
      }
      expect(canAccessPath(AdminRole.admin, '/orders/demo'), isTrue);
      expect(canAccessPath(AdminRole.superAdmin, '/staff'), isTrue);
      expect(canAccessPath(AdminRole.moderator, '/staff'), isFalse);
    });

    test('router wires every v2 screen', () {
      final router = File('lib/app/admin_router.dart').readAsStringSync();
      for (final screen in [
        'AdminGlobalSearchScreen',
        'AdminAiAssistantScreen',
        'AdminDocumentDetailScreen',
        'ProductCatalogScreen',
        'CategoryManagementScreen',
        'ReviewModerationScreen',
        'OrdersOperationsScreen',
        'RefundsOperationsScreen',
        'PaymentsOperationsScreen',
        'PaymobOperationsScreen',
        'SupportTicketsScreen',
        'PromotionsScreen',
        'RiskDashboardScreen',
        'AnalyticsScreen',
        'StaffManagementScreen',
      ]) {
        expect(router, contains(screen), reason: '$screen not routed');
      }
    });
  });
}
