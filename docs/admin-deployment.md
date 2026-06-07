# Admin Web Console Deployment

The public marketplace and admin console deploy to separate Firebase Hosting
targets in the same Firebase project.

## Main App

```powershell
flutter build web
firebase deploy --only hosting:main
```

## Admin App

```powershell
Set-Location apps/admin_web
flutter build web
Set-Location ../..
firebase deploy --only hosting:admin
```

Live admin URL: https://olmeg-connect-admin.web.app

Live public URL: https://olmeg-connect.web.app

## Safety Checks

- Confirm `build/web` is the public app output.
- Confirm `apps/admin_web/build/web` is the admin output.
- Confirm non-admin login reaches Access Denied.
- Confirm Firestore rules are deployed with admin role helpers.
- Roll back main and admin targets independently if needed.
