# Quickstart: Admin Web Console Plan Validation

## Manual Review

1. Confirm public app no longer includes admin navigation or public admin routes.
2. Confirm admin app has its own login and Access Denied page.
3. Confirm each admin route lists required roles in `route-structure.md`.
4. Confirm Firestore Rules plan maps each role to backend permissions.
5. Confirm Firebase Hosting has separate main and admin targets before deployment.
6. Confirm first super_admin bootstrap is documented and cannot be run accidentally twice.
7. Confirm role assignment requires a trusted backend/admin process and creates audit logs.

## Test Personas

- `buyer@example.com`: no admin role, must be denied.
- `moderator@example.com`: moderator role, moderation and reports only.
- `support@example.com`: support role, reports/support only.
- `admin@example.com`: admin role, operational admin pages.
- `superadmin@example.com`: super_admin role, all admin pages and role/audit access.

## Bootstrap Checks

1. Run the approved bootstrap process only in the intended Firebase project.
2. Confirm exactly one initial super_admin receives Custom Claims.
3. Confirm a bootstrap audit log exists.
4. Confirm a second bootstrap attempt is blocked or requires existing super_admin approval.
5. Confirm normal admins cannot assign or revoke roles.

## Verification Commands

```powershell
flutter test
```

```powershell
firebase emulators:exec "flutter test test/security"
```

```powershell
flutter build web
firebase deploy --only hosting:main
```

```powershell
Set-Location apps/admin_web
flutter test
flutter build web
Set-Location ../..
firebase deploy --only hosting:admin
```
