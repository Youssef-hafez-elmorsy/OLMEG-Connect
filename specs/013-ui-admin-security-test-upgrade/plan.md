# Implementation Plan: UI, Admin Mechanism, Security, and Test Upgrade

**Branch**: `013-ui-admin-security-test-upgrade` | **Date**: 2026-05-31 | **Spec**: [spec.md](./spec.md)  
**Input**: Premium marketplace UI/admin/security/test upgrade plan

## Summary

Implement the selected **Premium Marketplace** public app direction and **Admin Security Console** standalone admin direction while keeping security enforced by Firebase Rules, Custom Claims, callable backend commands, and immutable audit logs. This plan is an implementation slice on top of the enterprise roadmap; it does not replace Paymob-only payment scope or the separate admin web architecture.

## Technical Context

**Language/Version**: Dart SDK `>=3.0.0 <4.0.0`, Flutter 3.41.x, Node.js Cloud Functions  
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Firebase Auth/Firestore/Storage/Functions/Hosting, Paymob-only payments  
**Storage**: Cloud Firestore, Firebase Storage, Firebase Auth Custom Claims, audit logs, admin operational collections  
**Testing**: root/admin `flutter analyze`, root/admin `flutter test`, public/admin `flutter build web`, release APK build, Firebase rules dry-run, targeted security/admin/UI tests  
**Target Platform**: Flutter mobile/web public app, standalone Flutter Web admin app, Firebase backend  
**Project Type**: Multi-app Flutter marketplace with Firebase infrastructure  
**Constraints**: Admin UI route guards are not a security boundary; sensitive writes must use backend commands; all admin reads must remain capped/cursor based; Paymob remains the only payment provider

## Architecture Decisions

- Public app UI upgrades use existing `AppTheme`, shared app widgets, Riverpod providers, and GoRouter routes.
- Admin upgrades use `apps/admin_web`, `AdminScaffold`, `AdminDataGrid`, admin tokens, RBAC route definitions, and callable command services.
- Design direction is captured in [design-direction.md](./design-direction.md): public app follows the Premium Marketplace direction; admin web follows the Admin Security Console direction.
- Legacy `lib/features/admin` is quarantined as non-routed historical code until it can be deleted safely.
- Security hardening continues through `firestore.rules`, `storage.rules`, `functions/adminCommands.js`, and static/emulator tests.
- Every implementation batch updates [tasks.md](./tasks.md) and this plan's validation log.

## Project Structure

```text
specs/013-ui-admin-security-test-upgrade/
|-- spec.md
|-- plan.md
|-- quickstart.md
|-- tasks.md
`-- checklists/
    `-- acceptance.md

lib/
|-- core/
|-- features/
|   `-- admin/        # quarantined legacy public-app admin code

apps/admin_web/
|-- lib/
`-- test/

test/
|-- features/qa/
`-- security/
```

## Validation Log

| Date | Batch | Evidence | Status |
|---|---|---|---|
| 2026-05-31 | Design direction selection | User selected Premium Marketplace and Admin Security Console; added [design-direction.md](./design-direction.md) as implementation brief while Figma plugin handshake is unavailable | Complete |
| 2026-05-31 | Design implementation batch 1 | Added reusable buyer trust signal strip, seller verification card signal, admin visible server-side filter chips for core queues, and admin action policy tests; validated with targeted public/admin/security tests plus root/admin analyze | Passed |
| 2026-05-31 | Setup and guardrail batch | Created Spec Kit artifacts, added legacy admin quarantine marker, added admin/security tests, added product image evidence to moderation queue | Complete |
| 2026-05-31 | Public admin quarantine fix | Removed public order-provider dependency on quarantined `features/admin` audit code; replaced it with non-admin analytics tracking | Complete |
| 2026-05-31 | Targeted validation | `flutter test test/features/qa/admin_separation_test.dart test/security/storage_rules_test.dart test/security/admin_rules_test.dart`; `flutter test test/features/qa/buyer_ui_refresh_test.dart test/features/orders/order_creation_test.dart`; admin web `flutter test` | Passed |
| 2026-05-31 | Static/build gate validation | Root `flutter analyze`, admin `flutter analyze`, Firebase rules dry-run | Passed |
| 2026-05-31 | Root test suite | Root `flutter test` | Passed |
| 2026-05-31 | Web build gates | Public `flutter build web`; admin `flutter build web` | Passed |
| 2026-05-31 | APK release build | `flutter build apk --release`; artifact `build/app/outputs/flutter-apk/app-release.apk` | Passed |
| 2026-05-31 | OpenAI AI moderation upgrade | Added callable OpenAI Responses API product review with local fallback, admin AI evidence columns, protected AI review rules/index, `flutter test test/security/ai_services_test.dart test/security/admin_v2_hardening_test.dart`, `node -c functions/aiServices.js`, `flutter analyze` | Passed |
| 2026-05-31 | Full AI marketplace upgrade | Added AI search expansion, buyer recommendations, seller listing hints, audited admin assistant, admin route guard coverage; ran `node -c functions/aiServices.js`, root/admin `flutter analyze`, root/admin `flutter test`, public/admin `flutter build web`, buyer UI refresh, capacity readiness, admin route smoke | Passed |

## Implementation Order

1. Create Spec Kit artifacts and update active agent context.
2. Quarantine legacy public-app admin code and test it is not routed/imported outside the quarantine.
3. Improve admin evidence UI and guardrails, starting with product photos in moderation/catalog workflows.
4. Expand security tests for Storage Rules and admin/payment/audit boundaries.
5. Upgrade Premium Marketplace public app screens in controlled batches: home/discovery, product cards/detail, cart/checkout/Paymob result, orders, seller, chat/notifications/profile, Arabic RTL.
6. Upgrade Admin Security Console surfaces in controlled batches: dashboard, evidence queues, role-aware actions, server-side filters, detail/audit panels, Paymob operations.
7. Run validation gates and update `tasks.md`/checklists before deployment.
