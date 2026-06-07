# Tasks: Olmeg Connect Enterprise Roadmap

**Input**: Design documents from `/specs/003-enterprise-roadmap/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/enterprise-roadmap-contract.md, quickstart.md  
**Source Roadmap**: `docs/master-enterprise-roadmap-tasks.md`  
**Payment Scope**: Paymob only for Phase 4. PayPal, Stripe, Apple Pay, Google Pay, and multi-provider abstraction are out of scope.

## Phase 1: Setup

**Purpose**: Enroll the master enterprise roadmap in Spec Kit and link it to existing roadmap docs.

- [X] T001 Create Spec Kit roadmap folder and artifacts in `specs/003-enterprise-roadmap/`
- [X] T002 [P] Link source roadmap docs in `specs/003-enterprise-roadmap/plan.md`
- [X] T003 [P] Document Paymob-only payment boundary in `specs/003-enterprise-roadmap/contracts/enterprise-roadmap-contract.md`
- [X] T004 [P] Add phase gate checklist in `specs/003-enterprise-roadmap/checklists/phase-gates.md`
- [X] T005 Update active Spec Kit feature pointer in `.specify/feature.json`
- [X] T006 Update agent context plan reference in `AGENTS.md`

## Phase 2: Foundational Gates

**Purpose**: Define the non-negotiable gates that block all later roadmap work.

- [X] T007 Add Phase 0 stabilization acceptance criteria in `specs/003-enterprise-roadmap/spec.md`
- [X] T008 Add Phase 1 security lock acceptance criteria in `specs/003-enterprise-roadmap/spec.md`
- [X] T009 Add roadmap dependency rules in `specs/003-enterprise-roadmap/quickstart.md`
- [X] T010 Add payment provider scope constraints in `docs/master-enterprise-roadmap.md`
- [X] T011 Add phased task source document in `docs/master-enterprise-roadmap-tasks.md`

## Phase 3: User Story 1 - Lock Production Foundation (Priority: P1)

**Goal**: Make the current repository buildable, testable, and secure enough for enterprise expansion.

**Independent Test**: Run root/admin analyze, tests, build checks, and security rule checks; verify broad fallback and direct sensitive writes are closed.

- [X] T012 [US1] Fix admin compile failure in `apps/admin_web/lib/core/monitoring/admin_error_reporter.dart`
- [X] T013 [US1] Fix moderator first route expectation in `apps/admin_web/test/auth/admin_access_test.dart`
- [X] T014 [US1] Fix grouped navigation expectation in `apps/admin_web/test/ui/admin_v2_foundation_test.dart`
- [X] T015 [US1] Add `functions/node_modules/` ignore rule in `.gitignore`
- [X] T016 [US1] Confirm no service-account JSON files are tracked in `.gitignore`
- [X] T017 [US1] Replace broad Firestore fallback with deny-by-default in `firestore.rules`
- [X] T018 [US1] Add explicit chat rules in `firestore.rules`
- [X] T019 [US1] Tighten signed-in user read access in `firestore.rules`
- [X] T020 [US1] Add direct sensitive write denial tests in `test/security/admin_rules_test.dart`
- [X] T021 [US1] Harden merchant document access in `storage.rules`
- [X] T022 [US1] Run Phase 0 validation commands from `specs/003-enterprise-roadmap/quickstart.md`

## Phase 4: User Story 2 - Stabilize Enterprise Admin Operations (Priority: P1)

**Goal**: Turn the Admin Web Console into a reliable operations center instead of generic CRUD tables.

**Independent Test**: Log in as each staff role, verify allowed routes/actions, blocked routes/actions, bounded queries, detail pages, and audit-backed mutations.

- [ ] T023 [US2] Remove or quarantine legacy public admin code under `lib/features/admin/`
- [X] T024 [US2] Fix user restrict-post payload in `apps/admin_web/lib/features/users/users_management_screen.dart`
- [X] T025 [US2] Fix user mute-chat payload in `apps/admin_web/lib/features/users/users_management_screen.dart`
- [X] T026 [US2] Replace fake audit CSV snackbar in `apps/admin_web/lib/features/audit_logs/audit_logs_screen.dart`
- [X] T027 [US2] Add cursor pagination helper in `apps/admin_web/lib/core/firestore/admin_capped_query.dart`
- [X] T028 [US2] Add server-side filters to shared admin table in `apps/admin_web/lib/features/shared/admin_collection_table_page.dart`
- [X] T029 [US2] Add audit history panel to detail pages in `apps/admin_web/lib/features/operations/admin_document_detail_screen.dart`
- [X] T030 [US2] Add role-aware action visibility in `apps/admin_web/lib/core/rbac/admin_access.dart`
- [X] T031 [US2] Add admin release checklist in `specs/002-admin-web-console/checklists/admin-v2-release.md`

## Phase 5: User Story 3 - Build Analytics and Feedback Intelligence (Priority: P2)

**Goal**: Build event, session, funnel, and feedback foundations before AI and advanced dashboards.

**Independent Test**: Complete tracked user journeys and verify event-derived admin analytics summaries.

- [X] T032 [US3] Define analytics event schema in `specs/003-enterprise-roadmap/data-model.md`
- [X] T033 [US3] Add analytics event plan in `specs/003-enterprise-roadmap/contracts/enterprise-roadmap-contract.md`
- [X] T034 [US3] Create analytics implementation spec placeholder in `specs/005-analytics-and-feedback-intelligence/spec.md`
- [X] T035 [US3] Document dashboard metrics in `docs/master-enterprise-roadmap-tasks.md`
- [X] T036 [US3] Add analytics privacy constraints in `specs/003-enterprise-roadmap/research.md`

## Phase 6: User Story 4 - Launch Paymob Production Payments (Priority: P2)

**Goal**: Implement production-grade Paymob payments with backend verification, webhook handling, reconciliation, and admin payment operations.

**Independent Test**: Run Paymob success, failure, duplicate webhook, refund, and dispute scenarios; verify orders cannot be marked paid by client writes.

- [X] T037 [US4] Create Paymob implementation spec placeholder in `specs/006-paymob-production-payment-infrastructure/spec.md`
- [X] T038 [US4] Define Paymob payment states in `specs/003-enterprise-roadmap/data-model.md`
- [X] T039 [US4] Add Paymob-only scope to `docs/master-enterprise-roadmap.md`
- [X] T040 [US4] Add Paymob-only scope to `docs/master-enterprise-roadmap-tasks.md`
- [X] T041 [US4] Add Paymob webhook verification requirements in `specs/003-enterprise-roadmap/contracts/enterprise-roadmap-contract.md`
- [X] T042 [US4] Add Paymob phase gate checks in `specs/003-enterprise-roadmap/checklists/phase-gates.md`
- [X] T042a [US4] Add backend-created Paymob checkout sessions through `functions/index.js`
- [X] T042b [US4] Add Paymob HMAC webhook receiver and backend order/payment reconciliation in `functions/index.js`
- [X] T042c [US4] Block client payment writes in `firestore.rules`
- [X] T042d [US4] Switch checkout UI/provider labels from PayPal to Paymob in the public Flutter app
- [X] T042e [US4] Add Android SDK bridge scaffold and Paymob setup guide in `docs/paymob-integration.md`
- [X] T042f [US4] Add Paymob redirect result route and order-status confirmation screen in the Flutter app
- [X] T042g [US4] Add backend payment reconciliation records for Paymob intentions and webhooks
- [X] T042h [US4] Remove stale direct product payment path so Buy Now uses cart checkout and Paymob order flow

## Phase 7: User Story 5 - Expand Fulfillment, Notifications, AI, Sellers, and Scaling (Priority: P3)

**Goal**: Preserve a sequenced enterprise evolution plan for later systems without starting them before foundation gates pass.

**Independent Test**: Verify each future phase has entry gates, exit gates, and explicit dependency on stable foundation phases.

- [X] T043 [US5] Create fulfillment spec placeholder in `specs/007-fulfillment-and-disputes/spec.md`
- [X] T044 [US5] Create notification engine spec placeholder in `specs/008-dynamic-notification-engine/spec.md`
- [X] T045 [US5] Create AI moderation spec placeholder in `specs/009-ai-moderation-risk-engine/spec.md`
- [X] T046 [US5] Create AI marketplace intelligence spec placeholder in `specs/010-ai-marketplace-intelligence/spec.md`
- [X] T047 [US5] Create seller ecosystem spec placeholder in `specs/011-seller-ecosystem/spec.md`
- [X] T048 [US5] Create performance scaling spec placeholder in `specs/012-performance-scaling/spec.md`
- [X] T049 [US5] Document future phase dependency gates in `specs/003-enterprise-roadmap/checklists/phase-gates.md`

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Keep roadmap artifacts consistent and ready for future agents.

- [X] T050 Validate all roadmap tasks are represented in `specs/003-enterprise-roadmap/tasks.md`
- [ ] T051 Run Spec Kit analysis against `specs/003-enterprise-roadmap/spec.md`
- [X] T052 Update project README roadmap reference in `README.md`
- [X] T053 [P] Review roadmap docs for stale multi-provider payment references in `docs/master-enterprise-roadmap.md`
- [X] T054 [P] Review roadmap docs for stale multi-provider payment references in `docs/master-enterprise-roadmap-tasks.md`

## Dependencies & Execution Order

- Phase 1 establishes the Spec Kit artifacts.
- Phase 2 defines gates and blocks implementation phases.
- US1 must complete before US2, US3, US4, or US5 implementation begins.
- US2 should complete before advanced analytics or admin-heavy payment operations.
- US3 should complete before AI marketplace intelligence.
- US4 must remain Paymob-only and cannot start until US1 gates pass.
- US5 phases are future specs and must not start before their dependency gates pass.

## Parallel Opportunities

- T002, T003, and T004 can run in parallel after T001.
- T017 through T021 touch separate rules/tests areas and can be split carefully.
- T026 through T031 can be split by admin module after T023.
- T034 through T036 can be worked in parallel as analytics planning.
- T037 through T042 can be worked in parallel as Paymob planning after foundation gates.
- T043 through T048 are independent future spec placeholders.

## Implementation Strategy

1. Treat this feature as the master program plan, not a single coding sprint.
2. Complete Phase 0 stabilization and Phase 1 security first.
3. Stabilize admin operations second.
4. Add analytics before AI.
5. Build Paymob-only payments before any additional provider.
6. Create future detailed specs only when their entry gates pass.
