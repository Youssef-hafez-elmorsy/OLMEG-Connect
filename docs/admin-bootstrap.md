# Admin Bootstrap Runbook

This runbook defines the trusted one-time process for creating the first
`super_admin` account for the separated Olmeg Connect Admin Web Console.

## Rules

- Bootstrap is one-time and must run only against the intended Firebase project.
- Bootstrap must use the Firebase Admin SDK or another trusted backend-admin environment.
- Bootstrap must never run from the public Flutter app or unauthenticated UI.
- Bootstrap must write an immutable audit record after setting Custom Claims.
- A second bootstrap attempt must be blocked unless an existing `super_admin`
  approves the role through the trusted role manager.

## Required Inputs

- Firebase project id: `olmeg-connect`
- Target user uid
- Target user email
- Operator name
- Reason for bootstrap

## Expected Claims

```json
{
  "role": "super_admin",
  "admin": true,
  "roles": ["super_admin"]
}
```

## Verification

1. Confirm the user exists in Firebase Authentication.
2. Set the claims using Firebase Admin SDK.
3. Write an `admin_roles/{uid}` metadata record with `role = super_admin`.
4. Write an `audit_logs` record with action `bootstrap_super_admin`.
5. Ask the user to sign out and sign in again so the token refreshes.
6. Confirm the admin web console opens `/dashboard` and `/audit-logs`.

## Local Script

Use this only from a trusted machine with Firebase Admin credentials.

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\secure\olmeg-service-account.json"
node tools/set_admin_claim.js --email=admin@example.com --role=super_admin --actor=bootstrap --reason="Initial super admin"
```

For a normal admin:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\secure\olmeg-service-account.json"
node tools/set_admin_claim.js --email=admin@example.com --role=admin --actor=super_admin_uid --reason="Admin console access"
```

After the script runs, the user must sign out and sign in again at:

https://olmeg-connect-admin.web.app
