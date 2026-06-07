# Feature Specification: UI, Admin Mechanism, Security, and Test Upgrade

**Feature Branch**: `013-ui-admin-security-test-upgrade`  
**Created**: 2026-05-31  
**Status**: Active  
**Input**: Premium marketplace UI/admin/security/test upgrade request

## User Stories & Testing

### User Story 1 - Public App Premium Marketplace UI (Priority: P1)

As a buyer or seller, I need the mobile/web app to feel like a premium marketplace with trustworthy product discovery, clear checkout, polished seller flows, and strong Arabic/RTL behavior.

**Independent Test**: Public app widget/QA tests cover home, product cards, product detail, cart, checkout, orders, seller pages, chat, notifications, profile, Arabic RTL, and empty/error/loading states.

### User Story 2 - Admin Web Operations UI (Priority: P1)

As an admin operator, I need the Admin Web Console to behave like a commerce operations center with strong navigation, visible product/merchant evidence, filters, action bars, audit context, and responsive tables.

**Independent Test**: Admin web tests cover role routes, product photos, table guardrails, action visibility, detail/audit panels, and responsive navigation.

### User Story 3 - Admin Mechanism and Security Boundary (Priority: P1)

As a platform owner, I need sensitive admin work enforced by Cloud Functions, Custom Claims, Firestore Rules, Storage Rules, capped/cursor queries, and immutable audit logs, not UI hiding.

**Independent Test**: Security tests verify deny-by-default Firestore rules, protected Storage paths, payment write denial, admin collection protection, RBAC, and audit immutability.

### User Story 4 - Test and Release Gates (Priority: P1)

As a maintainer, I need a repeatable test/build/deploy process for public app, APK, admin web, and Firebase rules.

**Independent Test**: Root and admin analyze/test/build gates pass before deploy; plan/checklists are updated after each implementation batch.

## Requirements

- **FR-001**: The feature MUST live in `specs/013-ui-admin-security-test-upgrade/`.
- **FR-002**: Public app routes MUST remain in the public GoRouter and MUST NOT reintroduce admin routes.
- **FR-003**: Standalone admin routes MUST remain in `apps/admin_web`.
- **FR-004**: Premium app UI work MUST use shared theme/tokens/widgets instead of screen-only styling.
- **FR-005**: Admin UI work MUST use admin tokens, `AdminScaffold`, `AdminDataGrid`, detail panels, server-side filters, and backend command actions.
- **FR-006**: Product/admin evidence pages MUST show product images where product image fields exist.
- **FR-007**: Sensitive admin actions MUST use callable Cloud Functions with reason/audit evidence.
- **FR-008**: Firestore and Storage Rules MUST remain the security boundary.
- **FR-009**: Legacy public-app admin code MUST be quarantined and must not be routed from the public app.
- **FR-010**: Every implementation batch MUST update `tasks.md` and validation evidence before deployment.

## Success Criteria

- **SC-001**: Public app and admin web builds pass after UI/admin changes.
- **SC-002**: Root and admin tests pass for the changed areas.
- **SC-003**: Security rule dry-run passes before any rules deployment.
- **SC-004**: Admin web remains separately deployed at the admin hosting target.
- **SC-005**: Public app remains free of admin navigation and admin routes.

