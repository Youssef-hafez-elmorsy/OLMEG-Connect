enum AdminRole {
  moderator('moderator'),
  support('support'),
  admin('admin'),
  superAdmin('super_admin');

  final String value;
  const AdminRole(this.value);

  static AdminRole? fromClaim(String? value) {
    if (value == null) return null;
    for (final role in AdminRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

enum AdminCapability {
  dashboard,
  globalSearch,
  users,
  userDetail,
  productModeration,
  productCatalog,
  categoryManagement,
  reviewModeration,
  reports,
  reportDetail,
  merchantVerification,
  merchantDetail,
  notifications,
  promotions,
  orders,
  refunds,
  payments,
  supportTickets,
  risk,
  analytics,
  auditLogs,
  roleAssignment,
  settings,
  aiAssistant,
}

const adminRoleCapabilities = <AdminRole, Set<AdminCapability>>{
  AdminRole.moderator: {
    AdminCapability.globalSearch,
    AdminCapability.productModeration,
    AdminCapability.productCatalog,
    AdminCapability.reviewModeration,
    AdminCapability.reports,
    AdminCapability.reportDetail,
    AdminCapability.aiAssistant,
  },
  AdminRole.support: {
    AdminCapability.globalSearch,
    AdminCapability.userDetail,
    AdminCapability.reports,
    AdminCapability.reportDetail,
    AdminCapability.orders,
    AdminCapability.refunds,
    AdminCapability.supportTickets,
    AdminCapability.aiAssistant,
  },
  AdminRole.admin: {
    AdminCapability.dashboard,
    AdminCapability.globalSearch,
    AdminCapability.users,
    AdminCapability.userDetail,
    AdminCapability.productModeration,
    AdminCapability.productCatalog,
    AdminCapability.categoryManagement,
    AdminCapability.reviewModeration,
    AdminCapability.reports,
    AdminCapability.reportDetail,
    AdminCapability.merchantVerification,
    AdminCapability.merchantDetail,
    AdminCapability.notifications,
    AdminCapability.promotions,
    AdminCapability.orders,
    AdminCapability.refunds,
    AdminCapability.payments,
    AdminCapability.supportTickets,
    AdminCapability.risk,
    AdminCapability.analytics,
    AdminCapability.aiAssistant,
  },
  AdminRole.superAdmin: {
    AdminCapability.dashboard,
    AdminCapability.globalSearch,
    AdminCapability.users,
    AdminCapability.userDetail,
    AdminCapability.productModeration,
    AdminCapability.productCatalog,
    AdminCapability.categoryManagement,
    AdminCapability.reviewModeration,
    AdminCapability.reports,
    AdminCapability.reportDetail,
    AdminCapability.merchantVerification,
    AdminCapability.merchantDetail,
    AdminCapability.notifications,
    AdminCapability.promotions,
    AdminCapability.orders,
    AdminCapability.refunds,
    AdminCapability.payments,
    AdminCapability.supportTickets,
    AdminCapability.risk,
    AdminCapability.analytics,
    AdminCapability.auditLogs,
    AdminCapability.roleAssignment,
    AdminCapability.settings,
    AdminCapability.aiAssistant,
  },
};

extension AdminRoleAccess on AdminRole {
  bool can(AdminCapability capability) {
    return adminRoleCapabilities[this]?.contains(capability) ?? false;
  }

  bool get canManageRoles => can(AdminCapability.roleAssignment);
}
