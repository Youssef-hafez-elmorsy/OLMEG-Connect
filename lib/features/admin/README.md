# Legacy Admin Quarantine

This folder contains legacy public-app admin code that must not be routed,
linked, or imported by the public marketplace app.

Active admin operations live in the standalone Flutter Web app:

```text
apps/admin_web/
```

Rules for this quarantine:

- Do not add public app routes that point to `lib/features/admin`.
- Do not add profile/menu buttons that navigate to admin screens.
- Do not use this folder for new admin work.
- Move any still-needed behavior into `apps/admin_web` or trusted Cloud Functions.

