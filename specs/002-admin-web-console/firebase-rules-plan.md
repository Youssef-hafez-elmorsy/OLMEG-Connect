# Firebase Rules Plan

## Authorization Source

Use Firebase Custom Claims as the trusted authorization source for privileged admin access.

Expected claim shape:

```json
{
  "role": "admin",
  "admin": true,
  "roles": ["admin"]
}
```

Allowed role values:

- `moderator`
- `support`
- `admin`
- `super_admin`

Firestore admin role documents may exist for display, approval workflow, status, and claim-sync metadata, but Firestore documents alone must not be treated as sufficient for privileged access.

Mutable user-profile fields such as `users/{uid}.isAdmin` must never grant privileged access. The authorization boundary is Firebase Custom Claims plus Firestore Rules.

## Rule Helper Plan

Planned helper functions in `firestore.rules`:

```text
signedIn()
claimRole()
hasRole(role)
hasAnyRole(roles)
isModerator()
isSupport()
isAdmin()
isSuperAdmin()
isAdminStaff()
```

## Collection Permission Plan

| Collection/Area | moderator | support | admin | super_admin |
|-----------------|-----------|---------|-------|-------------|
| `users` | deny broad access; may read minimal reporter/seller context only when tied to assigned moderation item | limited support context only; personal fields such as phone/email require explicit support case scope | manage standard user actions except role escalation | manage all including role metadata |
| `products` moderation fields | review/update moderation state, reject/suspend products within moderation workflow | deny moderation writes | review/update moderation state and suspend products | full moderation access |
| `reports` | read/update assigned moderation reports | read/update support reports | manage reports | full report access |
| `merchant_verifications` | deny | deny | review/approve/reject | full access |
| `notifications` campaigns | deny | deny | create/manage campaigns | full access |
| `audit_logs` | create own moderation action records only; no broad reads | create own support action records only; no broad reads | create own admin action records only; limited reads for own actions if needed | read all and create |
| `admin_roles` / role metadata | deny | deny | read role labels only if needed; no writes | full access |
| Custom Claims assignment | deny | deny | deny | allowed only through trusted backend/admin process |

## Role Lifecycle Plan

- Bootstrap must create the first super_admin through a restricted script or backend-admin operation.
- Bootstrap must be one-time or idempotent and must not allow a second accidental super_admin creation without explicit super_admin approval.
- Client apps must never directly set Custom Claims.
- Role assignment requests should be handled by a trusted backend/admin process using Firebase Admin SDK.
- Every role change must write an immutable audit log with actor, target, previous role, new role, reason, and timestamp.
- If Custom Claims and Firestore role metadata disagree, the safer/lower privilege result must win until claim sync is repaired.
- Disabled staff accounts must be denied even if an old token still contains a privileged role after token refresh.

## Security Requirements

- Rules must deny non-admin users even if admin UI buttons are hidden.
- UI route guards are a usability layer only and must never be treated as the security boundary.
- Rules must deny role escalation by any role except super_admin.
- Audit logs must be append-only and immutable for normal admin actions.
- Admin table reads must be scoped and capped where possible.
- Broad fallback rules must explicitly exclude reserved admin collections such as `admin_roles`, `audit_logs`, `admin_notifications`, and `admin_role_requests`.
- Emulator tests or documented emulator checks must cover non-admin, moderator, support, admin, and super_admin personas.
- Emulator tests or documented emulator checks must cover stale claims, disabled staff, and role escalation denial.

## Public App Cleanup Rules

The public app may still read public marketplace data according to existing buyer/seller rules. It must not receive new broad admin read permissions just because the admin console exists.
