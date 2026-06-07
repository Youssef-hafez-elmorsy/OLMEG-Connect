# Data Model: Admin Web Console

## AdminUser

- `uid`: Firebase Auth uid.
- `email`: Staff email.
- `displayName`: Staff display name.
- `role`: One of moderator, support, admin, super_admin.
- `status`: active, disabled, pending_claim_sync.
- `claimsUpdatedAt`: Last known claim sync timestamp.
- `createdAt`: Staff record creation timestamp.
- `updatedAt`: Staff record update timestamp.

## AdminRole

- `name`: moderator, support, admin, super_admin.
- `permissions`: List of named capabilities.
- `description`: Human-readable role purpose.

## AdminRoute

- `path`: Route path.
- `title`: Navigation label.
- `allowedRoles`: Roles allowed to access.
- `fallbackRoute`: Redirect when denied.

## AuditLog

- `id`: Log id.
- `actorUid`: Admin uid.
- `actorRole`: Role at time of action.
- `action`: Action key.
- `targetType`: users, products, reports, merchant_verifications, notifications, roles.
- `targetId`: Target document or entity id.
- `metadata`: Non-sensitive action details.
- `createdAt`: Server timestamp.

## ModerationItem

- `id`: Target id.
- `type`: product, report, merchant, review, post.
- `status`: pending, approved, rejected, escalated, resolved.
- `assignedRole`: moderator, support, admin, super_admin.
- `updatedAt`: Last workflow update.

## HostingTarget

- `name`: main or admin.
- `firebaseProject`: olmeg-connect.
- `publicDirectory`: build output path.
- `siteUrl`: Hosting URL.
- `rollbackVersion`: Last known safe version.

## RoleAssignmentRequest

- `id`: Request id.
- `actorUid`: super_admin uid or bootstrap process id.
- `targetUid`: Staff account receiving the role change.
- `previousRole`: Existing role, if any.
- `newRole`: Requested role.
- `reason`: Required reason for the change.
- `status`: pending, applied, denied, failed.
- `createdAt`: Request timestamp.
- `appliedAt`: Timestamp when Custom Claims were updated.

## BootstrapAdmin

- `targetUid`: First super_admin uid.
- `targetEmail`: First super_admin email.
- `bootstrapSource`: Script, backend job, or controlled admin process.
- `executedAt`: Bootstrap execution timestamp.
- `status`: pending, applied, blocked.
- `auditLogId`: Audit record for traceability.
