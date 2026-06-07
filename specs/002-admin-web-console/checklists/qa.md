# QA Checklist: Olmeg Connect Admin Web Console

**Purpose**: Release checklist for separated admin web console security and deployment  
**Created**: 2026-05-16  
**Feature**: [spec.md](../spec.md)

## Authentication & Access

- [x] QA001 Signed-out admin URL opens admin login only.
- [x] QA002 Non-admin login shows Access Denied and signs out or redirects.
- [x] QA003 Admin login opens Dashboard.
- [x] QA004 Token refresh applies updated claims before protected content renders.
- [x] QA005 First super_admin bootstrap creates only the approved initial super_admin.
- [x] QA006 Second bootstrap attempt is blocked or requires existing super_admin approval.

## Role-Based Access

- [x] QA007 Moderator can access Product Moderation.
- [x] QA008 Moderator can access Reports.
- [x] QA009 Moderator cannot access Users Management, Merchant Verification, Notifications, or Audit Logs.
- [x] QA010 Support can access Reports/support workflows.
- [x] QA011 Support cannot access Product Moderation, Merchant Verification, Notifications, or Audit Logs.
- [x] QA012 Admin can access Dashboard, Users Management, Product Moderation, Reports, Merchant Verification, and Notifications.
- [x] QA013 Admin cannot assign super_admin or read unrestricted audit logs.
- [x] QA014 Super_admin can access every admin page and role assignment.
- [x] QA015 Support personal-data visibility is limited to approved support context.
- [x] QA016 Moderator product suspension/moderation scope matches the approved permission matrix.

## Public App Removal

- [x] QA017 Public app profile/settings/shell has no admin navigation entry.
- [x] QA018 Legacy public admin route redirects to public-safe page or not found.
- [x] QA019 Static scan finds no public admin menu labels or buttons.

## Firestore Rules

- [x] QA020 Non-admin direct Firestore admin reads are denied.
- [x] QA021 Moderator unauthorized writes are denied.
- [x] QA022 Support unauthorized moderation/notification writes are denied.
- [x] QA023 Admin role-escalation attempts are denied.
- [x] QA024 Super_admin privileged operations are allowed and audited.
- [x] QA025 Stale claims after role revocation are denied after token refresh.
- [x] QA026 Custom Claims and role metadata disagreement uses the safer/lower privilege result.

## Deployment

- [x] QA027 Main app deploy updates only main hosting target.
- [x] QA028 Admin app deploy updates only admin hosting target.
- [x] QA029 Admin build output path is not the public app build output.
- [x] QA030 Rollback instructions are validated for both targets.

## Performance & Safety

- [x] QA031 Admin tables use pagination, filters, or capped queries.
- [x] QA032 Audit logs avoid unbounded reads.
- [x] QA033 Admin actions create audit log entries where required.
- [x] QA034 Role changes create immutable audit logs with actor, target, old role, new role, reason, and timestamp.
- [x] QA035 Error states explain denied access and rules failures clearly.
- [x] QA036 Reserved admin collections are excluded from broad fallback Firestore rules.
- [x] QA037 Admin authorization does not trust mutable client-owned user profile fields.
- [x] QA038 UI route guards are documented as UX only, with Firestore Rules as the security boundary.
