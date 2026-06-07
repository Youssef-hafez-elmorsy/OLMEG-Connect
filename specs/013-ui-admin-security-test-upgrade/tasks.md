# Tasks: UI, Admin Mechanism, Security, and Test Upgrade

**Input**: Design documents from `/specs/013-ui-admin-security-test-upgrade/`  
**Prerequisites**: plan.md, spec.md, quickstart.md, checklists/acceptance.md  
**Scope**: Premium public app UI, Admin Web Console UI/mechanism, Firebase security, and test gates.

## Phase 1: Setup

- [X] T001 Create Spec Kit feature folder at `specs/013-ui-admin-security-test-upgrade/`
- [X] T002 Add `spec.md`, `plan.md`, `tasks.md`, `quickstart.md`, and checklist
- [X] T003 Update active feature pointer in `.specify/feature.json`
- [X] T004 Update `AGENTS.md` to reference the new plan

## Phase 2: Admin Separation and Quarantine

- [X] T005 Add quarantine marker for legacy public admin code in `lib/features/admin/README.md`
- [X] T006 Extend public admin separation tests to verify legacy admin is not imported or routed outside quarantine

## Phase 3: Admin UI and Mechanism Guardrails

- [X] T007 Add product image evidence to admin product moderation queue
- [X] T008 Add admin UI tests for product photo columns and action guardrail copy
- [X] T008A Add AI moderation evidence columns to the admin product moderation queue
- [X] T008B Add audited AI assistant route for admin operations
- [ ] T009 Apply Admin Security Console direction to dashboard, moderation, merchant, reports, payments, users, and audit surfaces
- [X] T010 Add exhaustive role-aware action visibility tests for admin row/header actions
- [ ] T011 Add detail/audit panel tests for users, merchants, reports, orders, and products
- [ ] T012 Upgrade admin filters from local-only filter to visible server-side filter controls per core table

## Phase 4: Security Guardrails

- [X] T013 Add static Storage Rules tests for merchant documents, public media, and deny-by-default fallback
- [ ] T014 Add emulator-backed Firestore rule tests for users, chats, products, orders, reviews, reports, payments, and admin collections
- [ ] T015 Add emulator-backed Storage rule tests for product images, review images, and merchant verification documents
- [ ] T016 Add Paymob webhook scenario tests for success, failure, duplicate webhook, refund, and dispute states
- [X] T016A Add protected AI moderation review collection rules, index coverage, and static backend tests
- [X] T016B Add OpenAI-backed AI callables with local fallback for search, recommendations, seller hints, moderation, and admin assistant

## Phase 5: Public App Premium UI

- [X] T017 Apply Premium Marketplace direction to shared buyer widgets, tokens, and responsive patterns
- [ ] T018 Upgrade and test premium marketplace home sections and responsive layout
- [X] T018A Add AI-ranked buyer recommendation section with existing product-card analytics
- [ ] T019 Upgrade and test product card/detail UI with trust, category, seller, delivery, and review signals
- [ ] T020 Upgrade and test cart, checkout, Paymob result, and orders UI
- [ ] T021 Upgrade and test seller center screens
- [X] T021A Add inline AI listing optimization hints to seller product submission
- [ ] T022 Upgrade and test chat, notifications, profile, settings, empty/error/loading states
- [ ] T023 Add Arabic/RTL UI regression tests for the upgraded screens

## Phase 6: Validation and Deployment Gates

- [X] T024 Run root `flutter analyze`
- [X] T025 Run root `flutter test`
- [X] T026 Run public `flutter build web`
- [X] T027 Run release APK build
- [X] T028 Run admin `flutter analyze`
- [X] T029 Run admin `flutter test`
- [X] T030 Run admin `flutter build web`
- [X] T031 Run Firebase rules dry-run
- [X] T032 Update `plan.md` validation evidence before any deploy

## Dependencies

- Phase 1 blocks all later phases.
- Phase 2 blocks any claim that admin access is fully moved out of the public app.
- Phase 4 blocks rules deployment.
- Phase 6 blocks public/admin hosting deployment.
