import 'admin_roles.dart';

enum AdminActionArea {
  users,
  merchants,
  productModeration,
  reports,
  payments,
  auditLogs,
  staff,
}

enum AdminActionVisibility {
  hidden,
  disabled,
  enabled,
}

class AdminActionPolicy {
  final String id;
  final String label;
  final AdminActionArea area;
  final AdminCapability capability;
  final Set<AdminRole> roles;
  final bool reasonRequired;

  const AdminActionPolicy({
    required this.id,
    required this.label,
    required this.area,
    required this.capability,
    required this.roles,
    this.reasonRequired = true,
  });

  AdminActionVisibility visibilityFor(AdminRole? role) {
    if (role == null || !roles.contains(role)) {
      return AdminActionVisibility.hidden;
    }
    if (!role.can(capability)) {
      return AdminActionVisibility.hidden;
    }
    return AdminActionVisibility.enabled;
  }
}

const adminActionPolicies = <AdminActionPolicy>[
  AdminActionPolicy(
    id: 'user_banned',
    label: 'Block user',
    area: AdminActionArea.users,
    capability: AdminCapability.users,
    roles: {AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'user_unblocked',
    label: 'Unblock user',
    area: AdminActionArea.users,
    capability: AdminCapability.users,
    roles: {AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'user_soft_deleted',
    label: 'Soft delete user',
    area: AdminActionArea.users,
    capability: AdminCapability.users,
    roles: {AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'merchant_verification_approved',
    label: 'Approve merchant',
    area: AdminActionArea.merchants,
    capability: AdminCapability.merchantVerification,
    roles: {AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'merchant_verification_rejected',
    label: 'Reject merchant',
    area: AdminActionArea.merchants,
    capability: AdminCapability.merchantVerification,
    roles: {AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'product_moderation_approved',
    label: 'Approve product',
    area: AdminActionArea.productModeration,
    capability: AdminCapability.productModeration,
    roles: {AdminRole.moderator, AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'product_moderation_rejected',
    label: 'Reject product',
    area: AdminActionArea.productModeration,
    capability: AdminCapability.productModeration,
    roles: {AdminRole.moderator, AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'report_resolved',
    label: 'Resolve report',
    area: AdminActionArea.reports,
    capability: AdminCapability.reports,
    roles: {
      AdminRole.moderator,
      AdminRole.support,
      AdminRole.admin,
      AdminRole.superAdmin,
    },
  ),
  AdminActionPolicy(
    id: 'payment_mark_reviewed',
    label: 'Mark payment reviewed',
    area: AdminActionArea.payments,
    capability: AdminCapability.payments,
    roles: {AdminRole.admin, AdminRole.superAdmin},
  ),
  AdminActionPolicy(
    id: 'audit_export',
    label: 'Export audit evidence',
    area: AdminActionArea.auditLogs,
    capability: AdminCapability.auditLogs,
    roles: {AdminRole.superAdmin},
    reasonRequired: false,
  ),
  AdminActionPolicy(
    id: 'staff_role_assigned',
    label: 'Assign staff role',
    area: AdminActionArea.staff,
    capability: AdminCapability.roleAssignment,
    roles: {AdminRole.superAdmin},
  ),
];

List<AdminActionPolicy> adminActionsForArea(
  AdminActionArea area, {
  required AdminRole? role,
}) {
  return adminActionPolicies.where((policy) {
    return policy.area == area &&
        policy.visibilityFor(role) == AdminActionVisibility.enabled;
  }).toList(growable: false);
}
