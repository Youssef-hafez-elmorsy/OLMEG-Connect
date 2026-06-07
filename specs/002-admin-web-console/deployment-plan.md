# Firebase Hosting Deployment Plan

## Hosting Targets

| Target | Purpose | Build Output | Example URL |
|--------|---------|--------------|-------------|
| `main` | Public Olmeg Connect marketplace app | `build/web` | `https://olmeg-connect.web.app` |
| `admin` | Standalone admin web console | `apps/admin_web/build/web` | `https://olmeg-connect-admin.web.app` or configured admin site |

## Firebase Project

Both hosting targets use the same Firebase project: `olmeg-connect`.

## Planned Commands

```powershell
flutter build web
firebase deploy --only hosting:main
```

```powershell
Set-Location apps/admin_web
flutter build web
Set-Location ../..
firebase deploy --only hosting:admin
```

## Firebase Configuration Plan

`firebase.json` should define separate hosting entries:

```json
{
  "hosting": [
    {
      "target": "main",
      "public": "build/web"
    },
    {
      "target": "admin",
      "public": "apps/admin_web/build/web"
    }
  ]
}
```

`.firebaserc` should map both targets to project sites once the admin site is created.

## Release Safety

- Main deploy must not upload `apps/admin_web/build/web`.
- Admin deploy must not upload public `build/web`.
- Admin deploy requires route/access tests and Firestore Rules checks first.
- Rollback steps must be documented for each target independently.
- Admin URL should not be linked from the public app for non-admin users.
