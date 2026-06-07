import 'admin_roles.dart';

class AdminSession {
  final String uid;
  final String email;
  final AdminRole? role;
  final bool disabled;

  const AdminSession({
    required this.uid,
    required this.email,
    required this.role,
    this.disabled = false,
  });

  bool get isAllowedStaff => role != null && !disabled;
}

class AdminRouteDefinition {
  final String path;
  final String title;
  final Set<AdminRole> roles;
  final AdminCapability? capability;
  final bool showInNavigation;
  final String group;

  const AdminRouteDefinition({
    required this.path,
    required this.title,
    required this.roles,
    this.capability,
    this.showInNavigation = true,
    this.group = 'Operations',
  });

  bool allows(AdminRole? role) => role != null && roles.contains(role);
}

const adminRoutes = <AdminRouteDefinition>[
  AdminRouteDefinition(
    path: '/dashboard',
    title: 'Dashboard',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.dashboard,
  ),
  AdminRouteDefinition(
    path: '/search',
    title: 'Global Search',
    roles: {
      AdminRole.moderator,
      AdminRole.support,
      AdminRole.admin,
      AdminRole.superAdmin,
    },
    capability: AdminCapability.globalSearch,
  ),
  AdminRouteDefinition(
    path: '/users',
    title: 'Users',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.users,
  ),
  AdminRouteDefinition(
    path: '/users/:userId',
    title: 'User Detail',
    roles: {AdminRole.support, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.userDetail,
    showInNavigation: false,
  ),
  AdminRouteDefinition(
    path: '/merchants',
    title: 'Merchants',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.merchantVerification,
  ),
  AdminRouteDefinition(
    path: '/merchants/:merchantId',
    title: 'Merchant Detail',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.merchantDetail,
    showInNavigation: false,
  ),
  AdminRouteDefinition(
    path: '/catalog/products',
    title: 'Catalog',
    roles: {AdminRole.moderator, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.productCatalog,
  ),
  AdminRouteDefinition(
    path: '/catalog/products/:productId',
    title: 'Product Detail',
    roles: {AdminRole.moderator, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.productCatalog,
    showInNavigation: false,
  ),
  AdminRouteDefinition(
    path: '/catalog/categories',
    title: 'Categories',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.categoryManagement,
  ),
  AdminRouteDefinition(
    path: '/moderation/products',
    title: 'Product Moderation',
    roles: {AdminRole.moderator, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.productModeration,
  ),
  AdminRouteDefinition(
    path: '/moderation/reviews',
    title: 'Review Moderation',
    roles: {AdminRole.moderator, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.reviewModeration,
  ),
  AdminRouteDefinition(
    path: '/reports',
    title: 'Reports',
    roles: {
      AdminRole.moderator,
      AdminRole.support,
      AdminRole.admin,
      AdminRole.superAdmin,
    },
    capability: AdminCapability.reports,
  ),
  AdminRouteDefinition(
    path: '/reports/:reportId',
    title: 'Report Detail',
    roles: {
      AdminRole.moderator,
      AdminRole.support,
      AdminRole.admin,
      AdminRole.superAdmin,
    },
    capability: AdminCapability.reportDetail,
    showInNavigation: false,
  ),
  AdminRouteDefinition(
    path: '/orders',
    title: 'Orders',
    roles: {AdminRole.support, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.orders,
  ),
  AdminRouteDefinition(
    path: '/orders/:orderId',
    title: 'Order Detail',
    roles: {AdminRole.support, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.orders,
    showInNavigation: false,
  ),
  AdminRouteDefinition(
    path: '/refunds',
    title: 'Refunds',
    roles: {AdminRole.support, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.refunds,
  ),
  AdminRouteDefinition(
    path: '/payments',
    title: 'Payments',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.payments,
  ),
  AdminRouteDefinition(
    path: '/payments/paymob',
    title: 'Paymob',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.payments,
  ),
  AdminRouteDefinition(
    path: '/support/tickets',
    title: 'Support',
    roles: {AdminRole.support, AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.supportTickets,
  ),
  AdminRouteDefinition(
    path: '/ai-assistant',
    title: 'AI Assistant',
    roles: {
      AdminRole.moderator,
      AdminRole.support,
      AdminRole.admin,
      AdminRole.superAdmin,
    },
    capability: AdminCapability.aiAssistant,
    group: 'Operations',
  ),
  AdminRouteDefinition(
    path: '/notifications',
    title: 'Notifications',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.notifications,
    group: 'Growth',
  ),
  AdminRouteDefinition(
    path: '/marketing/promotions',
    title: 'Promotions',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.promotions,
    group: 'Growth',
  ),
  AdminRouteDefinition(
    path: '/risk',
    title: 'Risk',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.risk,
    group: 'Governance',
  ),
  AdminRouteDefinition(
    path: '/analytics',
    title: 'Analytics',
    roles: {AdminRole.admin, AdminRole.superAdmin},
    capability: AdminCapability.analytics,
    group: 'Governance',
  ),
  AdminRouteDefinition(
    path: '/audit-logs',
    title: 'Audit Logs',
    roles: {AdminRole.superAdmin},
    capability: AdminCapability.auditLogs,
    group: 'Governance',
  ),
  AdminRouteDefinition(
    path: '/staff',
    title: 'Staff',
    roles: {AdminRole.superAdmin},
    capability: AdminCapability.roleAssignment,
    group: 'Governance',
  ),
  AdminRouteDefinition(
    path: '/settings',
    title: 'Settings',
    roles: {AdminRole.superAdmin},
    capability: AdminCapability.settings,
    group: 'Governance',
  ),
];

Iterable<String> adminNavigationGroupsFor(AdminRole role) {
  return adminRoutes
      .where((route) => route.showInNavigation && route.allows(role))
      .map((route) => route.group)
      .toSet();
}

Iterable<AdminRouteDefinition> adminNavigationRoutesFor(
  AdminRole role,
  String group,
) {
  return adminRoutes.where((route) {
    return route.showInNavigation && route.group == group && route.allows(role);
  });
}

bool canAccessPath(AdminRole? role, String path) {
  return routeForPath(path)?.allows(role) ?? false;
}

AdminRouteDefinition? routeForPath(String path) {
  for (final route in adminRoutes) {
    if (_matchesPathPattern(route.path, path)) return route;
  }
  return null;
}

bool _matchesPathPattern(String pattern, String path) {
  if (pattern == path) return true;
  final patternParts = pattern.split('/').where((part) => part.isNotEmpty);
  final pathParts = path.split('/').where((part) => part.isNotEmpty);
  if (patternParts.length != pathParts.length) return false;
  for (var i = 0; i < patternParts.length; i++) {
    final patternPart = patternParts.elementAt(i);
    final pathPart = pathParts.elementAt(i);
    if (patternPart.startsWith(':')) continue;
    if (patternPart != pathPart) return false;
  }
  return true;
}

String firstAllowedPath(AdminRole? role) {
  if (role == null) return '/access-denied';
  for (final route in adminRoutes) {
    if (route.showInNavigation &&
        route.path != '/search' &&
        route.allows(role)) {
      return route.path;
    }
  }
  for (final route in adminRoutes) {
    if (route.showInNavigation && route.allows(role)) return route.path;
  }
  return '/access-denied';
}

AdminRole? roleFromClaims(Map<String, dynamic>? claims) {
  if (claims == null) return null;
  final role = AdminRole.fromClaim(claims['role']?.toString());
  if (role != null) return role;

  final roles = claims['roles'];
  if (roles is Iterable) {
    for (final rawRole in roles) {
      final parsed = AdminRole.fromClaim(rawRole.toString());
      if (parsed != null) return parsed;
    }
  }
  if (claims['admin'] == true) return AdminRole.admin;
  return null;
}
