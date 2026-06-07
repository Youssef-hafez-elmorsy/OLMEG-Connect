import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/access_denied_screen.dart';
import '../auth/admin_auth_gate.dart';
import '../auth/admin_login_screen.dart';
import '../core/rbac/admin_access.dart';
import '../core/rbac/admin_roles.dart';
import '../features/audit_logs/audit_logs_screen.dart';
import '../features/ai/admin_ai_assistant_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/merchants/merchant_verification_screen.dart';
import '../features/moderation/product_moderation_screen.dart';
import '../features/notifications/admin_notifications_screen.dart';
import '../features/operations/admin_document_detail_screen.dart';
import '../features/operations/admin_global_search_screen.dart';
import '../features/operations/admin_operations_screens.dart';
import '../features/operations/staff_management_screen.dart';
import '../features/payments/paymob_operations_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/users/users_management_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final location = state.matchedLocation;
    final isLogin = location == '/login';
    final isDenied = location == '/access-denied';
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return isLogin ? null : '/login';
    final claims = await user.getIdTokenResult(true);
    final role = roleFromClaims(claims.claims);

    if (role == null) return isDenied ? null : '/access-denied';
    if (isLogin || isDenied) return firstAllowedPath(role);
    if (!canAccessPath(role, location)) return '/access-denied';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const AdminLoginScreen()),
    GoRoute(
      path: '/access-denied',
      builder: (_, __) => const AccessDeniedScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminAuthGate(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const AdminGlobalSearchScreen(),
        ),
        GoRoute(
          path: '/ai-assistant',
          builder: (_, __) => const AdminAiAssistantScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (_, __) => const UsersManagementScreen(),
        ),
        GoRoute(
          path: '/users/:userId',
          builder: (_, state) => AdminDocumentDetailScreen(
            title: 'User Detail',
            description:
                'Profile, orders, products, reports, tickets, notifications, restrictions, and timeline.',
            icon: Icons.person_search_outlined,
            collectionName: 'users',
            documentId: state.pathParameters['userId']!,
            relatedPanels: const [
              AdminRelatedPanel(
                title: 'Orders',
                collectionName: 'orders',
                fieldName: 'buyerId',
                icon: Icons.receipt_long_outlined,
              ),
              AdminRelatedPanel(
                title: 'Reports',
                collectionName: 'reports',
                fieldName: 'reporterId',
                icon: Icons.report_outlined,
              ),
              AdminRelatedPanel(
                title: 'Support Tickets',
                collectionName: 'support_tickets',
                fieldName: 'userId',
                icon: Icons.support_agent_outlined,
              ),
            ],
          ),
        ),
        GoRoute(
          path: '/merchants/:merchantId',
          builder: (_, state) => AdminDocumentDetailScreen(
            title: 'Merchant Detail',
            description:
                'Documents, store profile, seller performance, products, reports, and payout readiness.',
            icon: Icons.storefront_outlined,
            collectionName: 'merchant_verifications',
            documentId: state.pathParameters['merchantId']!,
            relatedPanels: const [
              AdminRelatedPanel(
                title: 'Products',
                collectionName: 'products',
                fieldName: 'sellerId',
                icon: Icons.inventory_2_outlined,
              ),
              AdminRelatedPanel(
                title: 'Reports',
                collectionName: 'reports',
                fieldName: 'targetId',
                icon: Icons.report_outlined,
              ),
            ],
          ),
        ),
        GoRoute(
          path: '/catalog/products',
          builder: (_, __) => const ProductCatalogScreen(),
        ),
        GoRoute(
          path: '/catalog/products/:productId',
          builder: (_, state) => AdminDocumentDetailScreen(
            title: 'Product Detail',
            description:
                'Product content, seller context, reports, reviews, and catalog status.',
            icon: Icons.inventory_2_outlined,
            collectionName: 'products',
            documentId: state.pathParameters['productId']!,
            relatedPanels: const [
              AdminRelatedPanel(
                title: 'Reviews',
                collectionName: 'reviews',
                fieldName: 'productId',
                icon: Icons.rate_review_outlined,
              ),
              AdminRelatedPanel(
                title: 'Reports',
                collectionName: 'reports',
                fieldName: 'targetId',
                icon: Icons.report_outlined,
              ),
            ],
          ),
        ),
        GoRoute(
          path: '/catalog/categories',
          builder: (_, __) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: '/moderation/products',
          builder: (_, __) => const ProductModerationScreen(),
        ),
        GoRoute(
          path: '/moderation/reviews',
          builder: (_, __) => const ReviewModerationScreen(),
        ),
        GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
        GoRoute(
          path: '/reports/:reportId',
          builder: (_, state) => AdminDocumentDetailScreen(
            title: 'Report Detail',
            description:
                'Reporter, target, moderation state, linked context, and escalation timeline.',
            icon: Icons.report_outlined,
            collectionName: 'reports',
            documentId: state.pathParameters['reportId']!,
          ),
        ),
        GoRoute(
          path: '/merchants',
          builder: (_, __) => const MerchantVerificationScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, __) => const OrdersOperationsScreen(),
        ),
        GoRoute(
          path: '/orders/:orderId',
          builder: (_, state) => AdminDocumentDetailScreen(
            title: 'Order Detail',
            description:
                'Order, payment, refund, buyer/seller context, and exception timeline.',
            icon: Icons.receipt_long_outlined,
            collectionName: 'orders',
            documentId: state.pathParameters['orderId']!,
            relatedPanels: const [
              AdminRelatedPanel(
                title: 'Payments',
                collectionName: 'payments',
                fieldName: 'orderId',
                icon: Icons.payments_outlined,
              ),
              AdminRelatedPanel(
                title: 'Refunds',
                collectionName: 'refunds',
                fieldName: 'orderId',
                icon: Icons.assignment_return_outlined,
              ),
            ],
          ),
        ),
        GoRoute(
          path: '/refunds',
          builder: (_, __) => const RefundsOperationsScreen(),
        ),
        GoRoute(
          path: '/payments',
          builder: (_, __) => const PaymentsOperationsScreen(),
        ),
        GoRoute(
          path: '/payments/paymob',
          builder: (_, __) => const PaymobOperationsScreen(),
        ),
        GoRoute(
          path: '/support/tickets',
          builder: (_, __) => const SupportTicketsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const AdminNotificationsScreen(),
        ),
        GoRoute(
          path: '/marketing/promotions',
          builder: (_, __) => const PromotionsScreen(),
        ),
        GoRoute(
          path: '/risk',
          builder: (_, __) => const RiskDashboardScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (_, __) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/audit-logs',
          builder: (_, __) => const AuditLogsScreen(),
        ),
        GoRoute(
          path: '/staff',
          builder: (_, __) => const StaffManagementScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const OperationsSettingsScreen(),
        ),
      ],
    ),
  ],
);

List<NavigationRailDestination> destinationsForRole(AdminRole role) {
  return [
    for (final route in adminRoutes)
      if (route.showInNavigation && route.allows(role))
        NavigationRailDestination(
          icon: const Icon(Icons.chevron_right),
          label: Text(route.title),
        ),
  ];
}
