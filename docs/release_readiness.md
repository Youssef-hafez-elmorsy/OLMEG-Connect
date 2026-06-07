# Olmeg Connect Release Readiness

## Environments

- Development: run with `--dart-define=APP_ENV=development` against the development Firebase project.
- Staging: run with `--dart-define=APP_ENV=staging` against staging Firebase rules and seed data.
- Production: run with `--dart-define=APP_ENV=production` and deploy to `olmeg-connect`.

## Release Build Checklist

- Run `flutter analyze`.
- Run `flutter test`.
- Run `flutter build web --release`.
- Confirm admin URL: `https://olmeg-connect.web.app/#/admin`.
- Confirm marketplace URL: `https://olmeg-connect.web.app/`.
- Smoke test login, home, product detail, cart, checkout, orders, chat, seller dashboard, and admin operations.
- Verify merchant delivery remains available only for approved merchants.
- Deploy hosting with `firebase deploy --only hosting --project olmeg-connect`.

## Privacy And Terms Review

- Payment events record order IDs, totals, and provider references only.
- Merchant verification stores business identity fields and admin review status.
- Reports, disputes, moderation history, and audit logs are retained for marketplace safety.
- Analytics events avoid storing raw payment credentials or private chat content.
- App error reporting stores error text, platform, stack trace, and timestamp.

## Monitoring

- `analytics_events`: commerce and recommendation behavior.
- `performance_events`: first-frame timings for home, product detail, checkout, chat, and order detail.
- `app_errors`: Flutter and platform errors captured at runtime.
- `audit_logs`: admin and seller operational actions.
- `moderation_history`: product, seller, review, post/report moderation decisions.

## Backup, Restore, And Retention

- Export Firestore daily from the Firebase/GCP scheduled backup console.
- Retain production backups for 30 days and staging backups for 7 days.
- Export Storage product images weekly and before major migrations.
- Restore procedure: create a temporary staging project, import backup, verify counts, then promote selected collections or run a controlled production restore.
- Retain audit logs, moderation history, reports, and disputes for marketplace safety review.
