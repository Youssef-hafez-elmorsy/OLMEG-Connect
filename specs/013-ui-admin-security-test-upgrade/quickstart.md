# Quickstart: UI/Admin/Security/Test Upgrade

## Required Validation Commands

Run after each implementation batch that touches the relevant area:

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk --release
```

```powershell
cd apps/admin_web
flutter analyze
flutter test
flutter build web
```

```powershell
firebase deploy --only firestore:rules,storage --dry-run
```

## Deployment Rules

- Deploy public web only after public app gates pass.
- Deploy admin web only after admin gates pass.
- Deploy Firebase Rules only after rule dry-run and security tests pass.
- Update `tasks.md`, `checklists/acceptance.md`, and `plan.md` validation evidence before deployment.

## Scope Rules

- Keep Paymob as the only payment provider.
- Do not add admin routes back into the public app.
- Do not rely on UI hiding for security.
- Do not mark a task complete without code/test evidence or an explicit documented gap.

