# Admin Access Contract

## Auth Contract

1. Admin app starts with no protected Firestore reads.
2. App waits for Firebase Auth state.
3. App refreshes or reads token claims.
4. App extracts role from trusted claims.
5. App routes user according to the role matrix.
6. App signs out or redirects denied users.

## Route Contract

```text
canAccess(route, role) -> allow | deny
```

Required behavior:

- `admin` and `super_admin` can access `/dashboard`.
- `moderator` can access `/moderation/products` and `/reports`.
- `support` can access `/reports`.
- Only `super_admin` can access `/audit-logs` and role assignment.
- Any missing or unknown role denies protected access.

## Firestore Contract

Direct Firestore requests must match the same or stricter role matrix as routes.

Required denied cases:

- Non-admin reads admin-only data.
- Moderator writes notifications.
- Support writes product moderation approvals.
- Admin assigns super_admin.
- Non-super_admin reads all audit logs.

Required allowed cases:

- Admin reads dashboard operational data.
- Moderator updates product moderation state.
- Support updates assigned support report.
- Super_admin reads audit logs and manages roles.

## Role Lifecycle Contract

```text
bootstrapSuperAdmin(targetUid, targetEmail) -> applied | blocked
assignRole(actorUid, targetUid, newRole, reason) -> applied | denied
revokeRole(actorUid, targetUid, reason) -> applied | denied
```

Required behavior:

- Bootstrap can create the first super_admin only through a trusted process.
- Bootstrap must be blocked or require explicit super_admin approval after the first super_admin exists.
- Only super_admin can assign, revoke, disable, or escalate admin roles.
- Client-side Firestore writes must not be able to grant admin privileges.
- Successful role changes must update Custom Claims and write an audit log.
- Failed role changes must not partially grant access.
