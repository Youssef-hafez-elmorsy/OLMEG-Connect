# Implementation Plan: Olmeg Connect Admin Web Console

**Branch**: `002-admin-web-console` | **Date**: 2026-05-16 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/002-admin-web-console/spec.md`

## Summary

Create a standalone Flutter Web admin console for Olmeg Connect using the same Firebase project as the public app, with its own login, role-gated routes, Firestore Rules enforcement, RBAC roles, separate Firebase Hosting target, and removal of admin navigation from the public mobile app. Security must be enforced by Firebase Custom Claims and Firestore Security Rules, with UI routing used only as a user experience layer.

The admin console must now evolve beyond basic tables into an Amazon/Noon-style marketplace operations console. The complete v2 roadmap is [admin-operations-v2-roadmap.md](./admin-operations-v2-roadmap.md), covering command center, global search, users, merchants, catalog, moderation, orders, payments, support, marketing, risk, analytics, audit, staff, and settings.

The implementation must start with the security wall: first super_admin bootstrap, trusted Custom Claims management, exact role permissions, immutable audit logs, pagination/capped reads, reserved admin collection protection, and rules tests. Admin pages should come after these foundations are in place.

## Technical Context

**Language/Version**: Dart SDK `>=3.0.0 <4.0.0`, Flutter Web  
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Firebase Core/Auth/Firestore/Functions/Hosting tooling, existing Olmeg Connect design/system utilities where safe to share  
**Storage**: Cloud Firestore for users, products, reports, merchant verification, notifications, audit logs, orders, payments, refunds, support tickets, campaigns, risk cases, admin summaries, and staff role metadata; Firebase Auth Custom Claims for trusted admin roles  
**Testing**: `flutter_test`, route/widget tests, callable function tests, static scans, Firestore emulator rules tests or documented emulator verification  
**Target Platform**: Web admin console, desktop-first responsive layout  
**Project Type**: Multi-app Flutter project with public app plus separate admin web app  
**Performance Goals**: Admin pages use capped or paginated queries by default; dashboard and tables avoid unbounded reads; initial admin shell loads without requesting protected data until role validation passes  
**Constraints**: Same Firebase project, separate Hosting target, no security-by-UI-only, public app must not expose admin navigation  
**Scale/Scope**: Marketplace operations console with 20+ role-aware routes, four roles, separate deployment pipeline, backend command layer, Firestore Rules updates, callable function authorization tests, and operational QA.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Codebase fit**: PASS. A separate `apps/admin_web` app keeps admin concerns out of the public buyer/seller app while allowing shared packages/utilities where appropriate.
- **Testing standard**: PASS with strict follow-up. Route access, public app admin removal, and Firestore Rules authorization are required test deliverables.
- **User experience consistency**: PASS. Admin has its own desktop-first layout and Access Denied flow, independent from public mobile navigation.
- **Security and privacy**: PASS with mandatory enforcement. Custom Claims and Firestore Rules are required; UI hiding/route guards are explicitly not the security boundary.
- **Performance**: PASS with follow-up. Operational tables must use capped/paginated queries and avoid unbounded admin reads.

## Project Structure

### Documentation (this feature)

```text
specs/002-admin-web-console/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── route-structure.md
├── firebase-rules-plan.md
├── deployment-plan.md
├── contracts/
│   └── admin-access-contract.md
├── checklists/
│   ├── requirements.md
│   └── qa.md
└── tasks.md
```

### Source Code (repository root)

```text
apps/
└── admin_web/
    ├── lib/
    │   ├── main.dart
    │   ├── app/
    │   │   ├── admin_app.dart
    │   │   └── admin_router.dart
    │   ├── auth/
    │   │   ├── admin_auth_gate.dart
    │   │   ├── admin_login_screen.dart
    │   │   └── access_denied_screen.dart
    │   ├── core/
    │   │   ├── rbac/
    │   │   ├── firebase/
    │   │   └── widgets/
    │   └── features/
    │       ├── dashboard/
    │       ├── users/
    │       ├── moderation/
    │       ├── reports/
    │       ├── merchants/
    │       ├── notifications/
    │       └── audit_logs/
    ├── test/
    │   ├── auth/
    │   ├── routing/
    │   └── features/
    └── web/

lib/
├── features/
│   └── admin/              # legacy admin surfaces to migrate or remove from public app
└── core/router/            # public app route cleanup

test/
├── features/qa/            # public app admin-removal guards
└── security/               # Firestore rules tests or emulator verification scripts

firebase.json               # main + admin hosting targets
firestore.rules             # role-enforced backend authorization
firestore.indexes.json      # admin table/query indexes
functions/                  # trusted admin command layer for v2 sensitive actions
```

**Structure Decision**: Use a separate Flutter Web app at `apps/admin_web` for admin operations. The public app should remove admin navigation and legacy public admin routes. Shared code may be extracted later into a common package only when it does not pull public-app UI dependencies into the admin boundary.

## Route Structure

The canonical route contract is [route-structure.md](./route-structure.md). Summary:

| Route | Page | Allowed Roles |
|-------|------|---------------|
| `/login` | Admin Login | signed-out or invalid session |
| `/access-denied` | Access Denied | non-admin or denied role |
| `/dashboard` | Dashboard | admin, super_admin |
| `/users` | Users Management | admin, super_admin |
| `/moderation/products` | Product Moderation | moderator, admin, super_admin |
| `/reports` | Reports | moderator, support, admin, super_admin |
| `/merchants` | Merchant Verification | admin, super_admin |
| `/notifications` | Notifications | admin, super_admin |
| `/audit-logs` | Audit Logs | super_admin |

V2 expands this route map with global search, details, orders, payments, support, marketing, risk, analytics, staff, and settings. See [admin-operations-v2-roadmap.md](./admin-operations-v2-roadmap.md).

## Firebase Rules Plan

Detailed rules plan is [firebase-rules-plan.md](./firebase-rules-plan.md). Rules must use helper functions for signed-in state, trusted role claims, and role hierarchy. UI route checks are not sufficient. Firestore Rules must deny unauthorized collection access and privileged writes even when requests bypass the admin web app. Rules must not trust mutable client-owned user profile fields for admin authorization, and broad fallback rules must exclude reserved admin collections.

Role lifecycle rules must deny all role escalation except super_admin. Custom Claims must be set by a trusted backend/admin process, and client writes must never directly grant privileged claims.

## Deployment Plan

Detailed deployment plan is [deployment-plan.md](./deployment-plan.md). Summary:

- Main app Hosting target: public Olmeg Connect marketplace app.
- Admin Hosting target: standalone admin console build output.
- Both targets use the same Firebase project.
- Admin deployment must not overwrite the main app and main deployment must not overwrite admin.

## Phase 0: Research

Research output is captured in [research.md](./research.md). Main decisions:

- Use Firebase Custom Claims as the primary trusted authorization source.
- Use Firestore role records only as supporting data and claim-sync metadata.
- Use a separate Flutter Web app instead of hidden public-app admin screens.
- Use Firestore Rules emulator tests or documented emulator checks for backend authorization.

## Phase 1: Design

Design output is captured in:

- [data-model.md](./data-model.md)
- [route-structure.md](./route-structure.md)
- [firebase-rules-plan.md](./firebase-rules-plan.md)
- [deployment-plan.md](./deployment-plan.md)
- [contracts/admin-access-contract.md](./contracts/admin-access-contract.md)
- [quickstart.md](./quickstart.md)

## Phase 2: Task Planning

Tasks are captured in [tasks.md](./tasks.md). Implementation should proceed in secure slices:

1. Separate admin app scaffold and Firebase initialization.
2. First super_admin bootstrap and trusted Custom Claims management path.
3. Admin auth gate, RBAC, login, access denied, and route tests.
4. Firestore Rules helpers and emulator/security tests.
5. Admin pages with capped queries and audit logs.
6. Public app admin route/navigation removal.
7. Firebase Hosting target split and QA checklist completion.

## Phase 3: Operations Console v2 Planning

The operations roadmap is captured in [admin-operations-v2-roadmap.md](./admin-operations-v2-roadmap.md). Implementation must proceed in this order:

1. Admin product foundation and shared UI components.
2. Backend command layer with callable functions and immutable audit logs.
3. Command-center dashboard.
4. Users operations.
5. Merchant and seller operations.
6. Moderation center.
7. Support desk.
8. Marketing and growth tools.
9. Orders, returns, and disputes.
10. Payments and refunds.
11. Catalog and category operations.
12. Audit and exports.
13. Staff and roles.
14. Risk dashboard.
15. Analytics.
16. Observability and hardening.

Implementation must not keep expanding direct client-side Firestore writes for sensitive actions. The v2 command layer is required before broad production usage of block/delete/approve/refund/send/role-change controls.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Separate Flutter Web app | Admin access must be removed from the public mobile app and deploy independently | Hiding admin screens in the public app leaves admin code/routes bundled with public UX and increases exposure risk |
| Custom Claims plus rules | Trusted authorization must survive client tampering | UI-only route guards can be bypassed by direct Firestore requests |
| Separate hosting target | Admin and public releases need independent deploy/rollback | A single hosting target risks overwriting the wrong build and exposing admin routes publicly |
| Trusted role bootstrap path | Custom Claims cannot be safely assigned from the client | Firestore-only role writes or UI role toggles can be tampered with and do not update token claims securely |
| Backend command layer | Amazon/Noon-style admin actions need trusted validation, Auth/FCM access, atomic audit behavior, and role enforcement | Client-only Firestore writes are easier but weaker, harder to audit, and cannot safely operate Auth/FCM/payment workflows |
| Detail pages and global search | Operators need context across users, merchants, products, orders, reports, and payments | Table-only pages force manual investigation and do not scale operationally |
