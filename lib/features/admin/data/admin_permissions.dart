import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';

enum AdminPermission {
  dashboard,
  support,
  moderation,
  merchants,
  users,
  reports,
  notifications,
  promotions,
  operations,
  finance,
  risk,
}

extension AdminPermissionChecks on UserEntity {
  bool canAdmin(AdminPermission permission) {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'admin' || normalizedRole == 'super_admin') {
      return true;
    }
    final rolePermissions = <String, Set<AdminPermission>>{
      'support_admin': {
        AdminPermission.dashboard,
        AdminPermission.support,
        AdminPermission.reports,
        AdminPermission.operations,
        AdminPermission.risk,
      },
      'moderation_admin': {
        AdminPermission.dashboard,
        AdminPermission.moderation,
        AdminPermission.reports,
        AdminPermission.operations,
      },
      'merchant_admin': {
        AdminPermission.dashboard,
        AdminPermission.merchants,
        AdminPermission.support,
        AdminPermission.operations,
      },
      'growth_admin': {
        AdminPermission.dashboard,
        AdminPermission.promotions,
        AdminPermission.notifications,
        AdminPermission.operations,
      },
      'ops_admin': {
        AdminPermission.dashboard,
        AdminPermission.support,
        AdminPermission.moderation,
        AdminPermission.merchants,
        AdminPermission.reports,
        AdminPermission.operations,
      },
      'finance_admin': {
        AdminPermission.dashboard,
        AdminPermission.finance,
        AdminPermission.operations,
      },
      'risk_admin': {
        AdminPermission.dashboard,
        AdminPermission.risk,
        AdminPermission.moderation,
        AdminPermission.reports,
      },
    };
    return rolePermissions[normalizedRole]?.contains(permission) ?? false;
  }
}

AdminPermission adminPermissionForRoute(String location) {
  if (location.startsWith('/admin/support')) return AdminPermission.support;
  if (location.startsWith('/admin/moderation')) {
    return AdminPermission.moderation;
  }
  if (location.startsWith('/admin/merchants')) {
    return AdminPermission.merchants;
  }
  if (location.startsWith('/admin/users')) return AdminPermission.users;
  if (location.startsWith('/admin/reports')) return AdminPermission.reports;
  if (location.startsWith('/admin/notify')) {
    return AdminPermission.notifications;
  }
  if (location.startsWith('/admin/promotions')) {
    return AdminPermission.promotions;
  }
  if (location.startsWith('/admin/operations')) {
    return AdminPermission.operations;
  }
  if (location.startsWith('/admin/finance')) return AdminPermission.finance;
  if (location.startsWith('/admin/risk')) return AdminPermission.risk;
  return AdminPermission.dashboard;
}
