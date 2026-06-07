# Tasks: Olmeg Connect Admin Web Console

**Input**: Design documents from `/specs/002-admin-web-console/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, route-structure.md, firebase-rules-plan.md, deployment-plan.md, contracts/admin-access-contract.md

**Tests**: Required. Security and access tests are mandatory for this feature.

## Phase 1: Setup

**Purpose**: Create the separated admin app boundary and shared planning hooks.

- [x] T001 Create standalone Flutter Web admin app scaffold in `apps/admin_web/`.
- [x] T002 Configure admin app Firebase initialization to use the same Firebase project settings as the main app in `apps/admin_web/lib/core/firebase/`.
- [x] T003 [P] Create admin app root shell and desktop-first layout placeholders in `apps/admin_web/lib/app/admin_app.dart`.
- [x] T004 [P] Create admin route registry and role metadata in `apps/admin_web/lib/app/admin_router.dart`.
- [x] T005 [P] Add admin RBAC constants and role matrix in `apps/admin_web/lib/core/rbac/admin_roles.dart`.

## Phase 2: Foundational Security

**Purpose**: Authentication, authorization, and backend rules that block all user stories until complete.

- [x] T006 Create admin login screen in `apps/admin_web/lib/auth/admin_login_screen.dart`.
- [x] T007 Create Access Denied screen in `apps/admin_web/lib/auth/access_denied_screen.dart`.
- [x] T008 Implement admin auth gate with Firebase token claim validation in `apps/admin_web/lib/auth/admin_auth_gate.dart`.
- [x] T009 Implement route guard helper using Custom Claims and role matrix in `apps/admin_web/lib/core/rbac/admin_access.dart`.
- [x] T010 Define exact role permission matrix including personal-data visibility, product suspension, user bans, merchant approvals, notifications, and audit access in `specs/002-admin-web-console/route-structure.md` and `specs/002-admin-web-console/firebase-rules-plan.md`.
- [x] T011 Create first super_admin bootstrap script or documented backend-admin process in `tools/bootstrap_super_admin.dart` or `docs/admin-bootstrap.md`.
- [x] T012 Create trusted Custom Claims role-assignment process for super_admin-only role changes in `tools/admin_role_manager.dart` or `functions/src/adminRoles.ts`.
- [x] T013 Update Firestore rule helpers for moderator, support, admin, and super_admin in `firestore.rules`.
- [x] T014 Add audit-log write contract and append-only permissions in `firestore.rules`.
- [x] T015 Add Firestore rules emulator test plan or test harness under `test/security/admin_rules_test.dart`.

## Phase 3: User Story 1 - Secure Admin Entry (Priority: P1)

**Goal**: Admin/super_admin users can log in and reach dashboard; non-admins are denied.

**Independent Test**: Route/widget tests verify non-admin denial and admin dashboard access.

- [x] T016 [P] [US1] Add non-admin route denial test in `apps/admin_web/test/auth/admin_access_test.dart`.
- [x] T017 [P] [US1] Add admin dashboard access test in `apps/admin_web/test/auth/admin_access_test.dart`.
- [x] T018 [US1] Implement login-to-dashboard flow in `apps/admin_web/lib/auth/admin_login_screen.dart`.
- [x] T019 [US1] Implement denied-user sign-out or redirect behavior in `apps/admin_web/lib/auth/access_denied_screen.dart`.
- [x] T020 [US1] Wire `/login`, `/access-denied`, and `/dashboard` routes in `apps/admin_web/lib/app/admin_router.dart`.

## Phase 4: User Story 2 - Role-Based Admin Operations (Priority: P1)

**Goal**: Moderator, support, admin, and super_admin users only access allowed routes.

**Independent Test**: Role matrix tests cover allowed and denied routes for all four roles.

- [x] T021 [P] [US2] Add moderator route access tests in `apps/admin_web/test/routing/role_routes_test.dart`.
- [x] T022 [P] [US2] Add support route access tests in `apps/admin_web/test/routing/role_routes_test.dart`.
- [x] T023 [P] [US2] Add admin and super_admin route access tests in `apps/admin_web/test/routing/role_routes_test.dart`.
- [x] T024 [US2] Implement Product Moderation page shell in `apps/admin_web/lib/features/moderation/product_moderation_screen.dart`.
- [x] T025 [US2] Implement Reports page shell in `apps/admin_web/lib/features/reports/reports_screen.dart`.
- [x] T026 [US2] Implement Users Management page shell in `apps/admin_web/lib/features/users/users_management_screen.dart`.
- [x] T027 [US2] Implement Merchant Verification page shell in `apps/admin_web/lib/features/merchants/merchant_verification_screen.dart`.
- [x] T028 [US2] Implement Notifications page shell in `apps/admin_web/lib/features/notifications/admin_notifications_screen.dart`.
- [x] T029 [US2] Implement Audit Logs page shell in `apps/admin_web/lib/features/audit_logs/audit_logs_screen.dart`.
- [x] T030 [US2] Register all protected routes with required role lists in `apps/admin_web/lib/app/admin_router.dart`.

## Phase 5: User Story 3 - Public App Admin Removal (Priority: P1)

**Goal**: Public app no longer exposes admin navigation or admin routes.

**Independent Test**: Static scan and route tests confirm no public admin entry points remain.

- [x] T031 [P] [US3] Add public app admin-navigation absence test in `test/features/qa/admin_separation_test.dart`.
- [x] T032 [US3] Remove admin navigation entries from public shell/profile/settings screens in `lib/features/shell/`, `lib/features/profile/`, and related public navigation files.
- [x] T033 [US3] Remove or redirect public admin routes from `lib/core/router/app_router.dart`.
- [x] T034 [US3] Quarantine legacy admin screens in `lib/features/admin/` for migration only or move reusable code to `apps/admin_web/`.

## Phase 6: User Story 4 - Firebase-Enforced Authorization (Priority: P1)

**Goal**: Firestore Rules enforce role access independently from UI route guards.

**Independent Test**: Firestore emulator tests prove unauthorized access is denied and authorized role operations pass.

- [x] T035 [P] [US4] Add non-admin Firestore denial tests in `test/security/admin_rules_test.dart`.
- [x] T036 [P] [US4] Add moderator allowed/denied Firestore tests in `test/security/admin_rules_test.dart`.
- [x] T037 [P] [US4] Add support allowed/denied Firestore tests in `test/security/admin_rules_test.dart`.
- [x] T038 [P] [US4] Add admin and super_admin Firestore tests in `test/security/admin_rules_test.dart`.
- [x] T039 [P] [US4] Add stale-claims and role-escalation denial tests in `test/security/admin_rules_test.dart`.
- [x] T040 [US4] Implement role-specific collection rules for users, products, reports, merchant verifications, notifications, and audit logs in `firestore.rules`.
- [x] T041 [US4] Add audit logging service for admin actions in `apps/admin_web/lib/core/audit/admin_audit_service.dart`.
- [x] T042 [US4] Add capped query/index requirements for admin tables in `firestore.indexes.json`.
- [x] T043 [US4] Add immutable audit records for role changes, bans, moderation decisions, merchant approvals, and notification campaigns in `apps/admin_web/lib/core/audit/admin_audit_service.dart`.

## Phase 7: User Story 6 - Admin Role Lifecycle and Bootstrap (Priority: P1)

**Goal**: First super_admin and future role changes are handled through trusted processes with audit evidence.

**Independent Test**: Bootstrap and role-change tests prove only trusted bootstrap or super_admin can assign roles.

- [x] T044 [P] [US6] Add first super_admin bootstrap test or documented verification in `test/security/admin_bootstrap_test.dart`.
- [x] T045 [P] [US6] Add super_admin-only role assignment tests in `test/security/admin_role_assignment_test.dart`.
- [x] T046 [US6] Implement one-time bootstrap guard in `tools/bootstrap_super_admin.dart` or trusted backend role manager.
- [x] T047 [US6] Implement role-change audit metadata with actor, target, old role, new role, reason, and timestamp in the trusted role manager.
- [x] T048 [US6] Document bootstrap and role management runbook in `docs/admin-bootstrap.md`.

## Phase 8: User Story 5 - Admin Hosting and Release Separation (Priority: P2)

**Goal**: Main app and admin panel deploy separately to Firebase Hosting targets.

**Independent Test**: Build/deploy dry run or documented verification confirms targets and build outputs do not overlap.

- [x] T049 [P] [US5] Update `firebase.json` with separate `main` and `admin` hosting targets.
- [x] T050 [P] [US5] Update `.firebaserc` target mapping for main and admin hosting sites after admin site creation.
- [x] T051 [US5] Add admin build/deploy script or documentation in `docs/admin-deployment.md`.
- [x] T052 [US5] Add deployment verification checklist to `specs/002-admin-web-console/checklists/qa.md`.

## Phase 9: Polish & Release Validation

**Purpose**: Cross-cutting verification before release.

- [x] T053 Run public app `flutter analyze` and `flutter test`.
- [x] T054 Run admin app `flutter analyze` and `flutter test` from `apps/admin_web/`.
- [x] T055 Run Firestore rules tests or emulator verification for admin access.
- [x] T056 Build public app web output with `flutter build web`.
- [x] T057 Build admin app web output from `apps/admin_web/`.
- [x] T058 Complete QA checklist in `specs/002-admin-web-console/checklists/qa.md`.
- [x] T059 Harden admin guardrails so tables use capped-query helpers, sensitive actions create immutable audit records, reserved admin collections cannot fall through broad rules, and UI route guards are documented as non-security boundaries.

## Phase 10: Admin Operations Console v2 - Product Foundation

**Goal**: Upgrade the admin from collection tables to an Amazon/Noon-style operations product.

**Independent Test**: Widget/static tests verify every v2 page uses shared admin components, route metadata, role access, and non-placeholder states.

- [x] T060 Add v2 roadmap reference to all admin planning artifacts.
- [x] T061 Design shared admin component system: `AdminScaffold`, `AdminDataGrid`, `AdminDetailDrawer`, `AdminActionDialog`, `AdminStatusBadge`, and `AdminMetricCard`.
- [x] T062 Replace ad-hoc admin page layouts with shared v2 shell, top bar, breadcrumbs, global search entry, and role-aware navigation groups.
- [x] T063 Add design tokens for admin density, table spacing, status colors, severity colors, destructive actions, and dashboard metrics.
- [x] T064 Add accessibility and keyboard navigation tests for tables, dialogs, drawers, and navigation.
- [x] T065 Add no-placeholder test: each operational route must have real data, empty/loading/error states, and at least one role-appropriate workflow.

## Phase 11: Admin Operations Console v2 - Trusted Command Layer

**Goal**: Move sensitive admin actions to backend callable commands with role validation and immutable audits.

**Independent Test**: Callable function tests prove unauthorized roles are denied and every successful command writes an audit log.

- [x] T066 Scaffold Firebase Callable Functions admin command module under `functions/`.
- [x] T067 Implement shared command guard for Custom Claims role validation, required reason, target validation, and safe transition checks.
- [x] T068 Implement `adminBlockUser`, `adminUnblockUser`, `adminRestrictUserPosting`, `adminMuteUserChat`, and `adminSoftDeleteUser`.
- [x] T069 Implement `adminApproveMerchant`, `adminRejectMerchant`, `adminSuspendMerchant`, and merchant-dependent product status sync.
- [x] T070 Implement `adminApproveProduct`, `adminRejectProduct`, `adminHideProduct`, and `adminEscalateProduct`.
- [x] T071 Implement `adminResolveReport`, `adminDismissReport`, and `adminEscalateReport`.
- [x] T072 Implement `adminCreateNotificationCampaign` and `adminCancelNotificationCampaign` with capped preview and controlled fanout.
- [x] T073 Implement `adminAssignStaffRole` and `adminDisableStaff` with last-super-admin protection.
- [x] T074 Add typed admin web command client and migrate UI actions away from direct sensitive Firestore writes.
- [x] T075 Add function authorization, validation, and audit-log tests.

## Phase 12: Admin Operations Console v2 - Command Center

**Goal**: Build a real marketplace command dashboard.

**Independent Test**: Dashboard loads actionable KPIs and queues without unbounded reads.

- [x] T076 Define admin summary documents or aggregation jobs for dashboard metrics.
- [x] T077 Add KPI cards: users, merchants, products, orders, reports, support tickets, payments, refunds, and risk alerts.
- [x] T078 Add alert panel for high-severity reports, payment failures, seller SLA breaches, and suspicious activity.
- [x] T079 Add queue shortcut cards for moderation, merchants, reports, support, refunds, and risk.
- [x] T080 Add time-range filters and role-specific dashboard visibility.

## Phase 13: Admin Operations Console v2 - Users and Merchants

**Goal**: Add detail-first user and seller operations.

**Independent Test**: Admin can investigate user/merchant context and execute backend commands with audit records.

- [x] T081 Build global user search by uid, email, display name, phone, and status.
- [x] T082 Build user detail page with profile, orders, products, reports, tickets, notifications, restrictions, and timeline.
- [x] T083 Add user action workflows using backend commands: block, unblock, restrict posts, mute chat, soft delete, restore, add note.
- [x] T084 Build merchant detail page with documents, store profile, seller performance, products, reports, and payout readiness.
- [x] T085 Add merchant workflows using backend commands: approve, reject, suspend, restore, request more info, add note.

## Phase 14: Admin Operations Console v2 - Catalog and Moderation

**Goal**: Operate the marketplace catalog and moderation queues professionally.

**Independent Test**: Moderator/admin can process queues with detail context and audit logs.

- [x] T086 Build product catalog route with search, filters, category/seller/status filters, and product detail.
- [x] T087 Build category management for categories, subcategories, visibility, sort order, and delivery/category rules.
- [x] T088 Build product moderation queue with image preview, seller risk, reason, severity, and detail drawer.
- [x] T089 Build review moderation queue.
- [x] T090 Add moderation workflows: approve, reject with reason, hide, escalate, assign, bulk-safe actions.

## Phase 15: Admin Operations Console v2 - Orders, Payments, and Support

**Goal**: Add marketplace operations beyond catalog management.

**Independent Test**: Support/admin can investigate orders, returns, refunds, payment failures, and support tickets with scoped permissions.

- [x] T091 Build order search and order detail pages.
- [x] T092 Build return/refund/dispute exception queues.
- [x] T093 Build payment attempts, failed payment, payout readiness, and reconciliation views.
- [x] T094 Build support ticket queue with SLA, priority, category, assignee, status, and linked context.
- [x] T095 Add support workflows: assign, escalate, resolve, add internal note, link order/user/product/report.

## Phase 16: Admin Operations Console v2 - Marketing, Risk, Audit, Staff, Analytics

**Goal**: Add growth, trust, compliance, staff, and business intelligence capabilities.

**Independent Test**: Admin/super_admin can run campaigns, review risk, export audits, manage staff, and view analytics under role constraints.

- [x] T096 Build notification campaign builder with audience filters, preview, test send, schedule/send now, and delivery stats.
- [x] T097 Build promotions/coupons/home-banner/featured-picks management.
- [x] T098 Build risk dashboard with suspicious users, sellers, products, payments, watchlist, and case timeline.
- [x] T099 Upgrade audit logs with filters, detail view, CSV export, and high-risk action alerts.
- [x] T100 Build staff management: invite, assign role, disable, role history, and self-escalation protection.
- [x] T101 Build analytics views for GMV, product/category performance, seller performance, cohorts, and conversion where data exists.

## Phase 17: Admin Operations Console v2 - Production Hardening

**Goal**: Make the big e-commerce admin safe to run in production.

**Independent Test**: Release checklist includes security, function, route, performance, and deployment evidence.

- [x] T102 Add end-to-end smoke tests for every v2 route and role.
- [x] T103 Add function load/error monitoring and admin web error reporting.
- [x] T104 Add Firestore index coverage for all v2 filters and queues.
- [x] T105 Add performance checks for dashboard, global search, and high-volume queues.
- [x] T106 Add release checklist covering no UI-only sensitive actions, audit coverage, no unbounded reads, and rollback.

## Dependencies & Execution Order

- Phase 1 must complete before all other phases.
- Phase 2 blocks all user stories because auth and rules are foundational.
- User Stories 1, 2, 3, and 4 are all P1; implement US1 and US4 first for security, then US2 and US3.
- User Story 6 depends on foundational security and must complete before production role management is enabled.
- User Story 5 depends on admin app structure from Phase 1 and must complete before deployment.
- Phase 9 validates all selected stories.
- Phase 10 must complete before major v2 page work to avoid inconsistent layouts.
- Phase 11 must complete before sensitive v2 actions are considered production-ready.
- Phases 13 through 16 can proceed by module after Phase 10, but sensitive actions must use Phase 11 commands.

## Parallel Opportunities

- T003, T004, and T005 can run in parallel after T001.
- Role route tests T021, T022, and T023 can run in parallel.
- Public app removal test T031 can run while admin pages are scaffolded.
- Firestore rules persona tests T035 through T039 can be written in parallel before rules implementation.
- Bootstrap and role assignment tests T044 and T045 can be written in parallel.
- Hosting config T049 and target mapping T050 can be prepared in parallel after the admin site exists.
- V2 modules can be parallelized by domain after shared components and command contracts are stable: Users/Merchants, Catalog/Moderation, Orders/Support, Marketing/Risk, Audit/Staff.

## Implementation Strategy

1. Build the admin auth boundary first.
2. Define exact role permissions, bootstrap, and trusted role assignment before adding operational pages.
3. Prove non-admin denial before adding operational pages.
4. Add role-based routes and page shells.
5. Remove admin navigation from the public app.
6. Harden Firestore Rules and emulator tests.
7. Split hosting targets.
8. Complete QA and only then deploy.
9. Upgrade to v2 through shared components first, backend commands second, then domain modules.
10. Treat each v2 module as incomplete until it has detail views, filters, actions, audit logs, tests, and capped reads.
