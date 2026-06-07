# Feature Specification: Olmeg Connect Admin Web Console

**Feature Branch**: `002-admin-web-console`  
**Created**: 2026-05-16  
**Status**: Draft  
**Input**: User description: "Create a separate Olmeg Connect Admin Web Console. Move admin access out of the mobile app into a standalone Flutter Web admin panel. Use same Firebase project, own login, Custom Claims or admin roles, Access Denied for non-admins, remove admin navigation from public app, enforce permissions in Firestore Rules, add RBAC roles, admin pages, hosting plan, tests, route structure, Firebase rules plan, deployment plan, QA checklist. Upgrade the admin page to a big e-commerce marketplace operations console like Amazon/Noon."

**Operations v2 Roadmap**: [admin-operations-v2-roadmap.md](./admin-operations-v2-roadmap.md)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Admin Entry (Priority: P1)

An admin user can open a dedicated web admin URL, sign in through an admin-only login page, and reach the dashboard only when their account has an approved administrative role.

**Why this priority**: Admin access controls marketplace safety, user data, moderation, and notifications. The first deliverable must make admin entry secure before adding operational pages.

**Independent Test**: A signed-in user with an admin or super_admin role can access the admin dashboard, while a normal buyer/seller receives Access Denied and cannot reach protected routes.

**Acceptance Scenarios**:

1. **Given** a user opens the admin web URL while signed out, **When** the page loads, **Then** they see the admin login page and no admin data is requested.
2. **Given** a signed-in user has Firebase Custom Claims with role `admin` or `super_admin`, **When** they open `/dashboard`, **Then** the dashboard loads.
3. **Given** a signed-in user has no admin claim and no allowed admin role record, **When** they open any admin route, **Then** they see Access Denied and are signed out or redirected away.
4. **Given** a token claim changes, **When** the user refreshes or the auth state is rechecked, **Then** the admin panel applies the new permission before showing protected content.

---

### User Story 2 - Role-Based Admin Operations (Priority: P1)

Administrative staff can access only the pages allowed by their role: moderator, support, admin, or super_admin.

**Why this priority**: A single admin flag is too broad. Moderation, support, notification, user management, and audit access must be separated to reduce operational and privacy risk.

**Independent Test**: Test accounts for moderator, support, admin, and super_admin can each sign in and are allowed or denied by route according to the role matrix.

**Acceptance Scenarios**:

1. **Given** a moderator signs in, **When** they navigate, **Then** they can access Product Moderation and Reports but not Users Management, Notifications, Merchant Verification, or Audit Logs.
2. **Given** a support user signs in, **When** they navigate, **Then** they can access Reports and support-relevant user/order context but not moderation approval, notifications, merchant approval, or audit-log management.
3. **Given** an admin signs in, **When** they navigate, **Then** they can access Dashboard, Users Management, Product Moderation, Reports, Merchant Verification, and Notifications.
4. **Given** a super_admin signs in, **When** they navigate, **Then** they can access every admin page including Audit Logs and role management.

---

### User Story 3 - Public App Admin Removal (Priority: P1)

The public mobile/web marketplace app no longer exposes admin navigation, admin routes, or admin dashboards to buyer/seller users.

**Why this priority**: Removing admin surfaces from the public app reduces accidental exposure and makes the public app simpler to test, deploy, and secure.

**Independent Test**: A scan and route test confirm the public app no longer renders admin menu entries or navigates to admin screens, while admin functionality remains available only in the admin web app.

**Acceptance Scenarios**:

1. **Given** a public app user opens the profile, shell, settings, or navigation drawer, **When** the UI renders, **Then** no admin entry point is visible.
2. **Given** a user tries a legacy public-app admin route, **When** routing resolves, **Then** the app redirects to a safe public page or shows not found.
3. **Given** the admin web app is deployed, **When** authorized staff need admin tools, **Then** they use the dedicated admin URL instead of the public app.

---

### User Story 4 - Firebase-Enforced Authorization (Priority: P1)

Admin permissions are enforced by Firebase Custom Claims and Firestore Security Rules, not only by hiding buttons or routes in the UI.

**Why this priority**: UI hiding is helpful for usability but not security. Rules must block unauthorized reads and writes even if a user manually calls Firestore or tampers with the web client.

**Independent Test**: Firestore rules emulator tests verify that non-admins cannot read or write admin-only collections/actions, moderators/support users can only access role-allowed data, and super_admin can perform privileged actions.

**Acceptance Scenarios**:

1. **Given** a non-admin authenticated user, **When** they try to read admin-only users, reports, moderation, merchant verification, notifications, or audit data directly, **Then** Firestore Rules deny the request.
2. **Given** a moderator, **When** they attempt product moderation actions, **Then** allowed moderation reads/writes succeed and unrelated admin writes fail.
3. **Given** a support user, **When** they access reports/support queues, **Then** allowed support reads/writes succeed and moderation/notification writes fail.
4. **Given** an admin role is changed, **When** the user refreshes their auth token, **Then** the new Custom Claims and rules behavior apply.

---

### User Story 5 - Admin Hosting and Release Separation (Priority: P2)

The team can deploy the public marketplace and admin web console to separate Firebase Hosting targets using the same Firebase project and a documented release process.

**Why this priority**: Separate hosting reduces accidental public exposure and lets the team deploy admin fixes independently from buyer-facing UI changes.

**Independent Test**: Deployment documentation shows separate hosting targets, build outputs, URLs, rollback steps, and verification checks for main app and admin panel.

**Acceptance Scenarios**:

1. **Given** a release operator builds the public app, **When** they deploy, **Then** only the main hosting target changes.
2. **Given** a release operator builds the admin app, **When** they deploy, **Then** only the admin hosting target changes.
3. **Given** a bad admin release is detected, **When** rollback is needed, **Then** the admin target can be rolled back without redeploying the public app.

---

### User Story 6 - Admin Role Lifecycle and Bootstrap (Priority: P1)

A super_admin can safely bootstrap and manage admin roles through a trusted backend/admin process, with every role change audited and reflected in Firebase Custom Claims before access is granted.

**Why this priority**: A secure admin console needs a secure way to create the first super_admin and manage future roles. If role assignment is weak, the whole admin system is weak.

**Independent Test**: A bootstrap path creates exactly one initial super_admin through a trusted process, and role-change tests prove only super_admin can assign, revoke, or escalate admin roles.

**Acceptance Scenarios**:

1. **Given** no super_admin exists, **When** the approved bootstrap process runs, **Then** exactly one configured account receives the initial super_admin Custom Claims and an audit record is created.
2. **Given** an admin attempts to assign super_admin, **When** the request is evaluated, **Then** it is denied because only super_admin can manage role escalation.
3. **Given** a super_admin changes a staff role, **When** the change completes, **Then** Custom Claims, role metadata, and audit logs are updated together.
4. **Given** a staff user is disabled or downgraded, **When** their token refreshes or they re-enter the admin console, **Then** access is reduced or revoked before protected data is shown.

---

### User Story 7 - Big E-Commerce Operations Console (Priority: P1)

Marketplace operators can run Olmeg Connect like a serious e-commerce platform, with command-center KPIs, global search, operational queues, detail pages, backend action commands, support tools, catalog controls, seller operations, order/payment exception handling, marketing campaigns, risk review, analytics, audit exports, and staff management.

**Why this priority**: The current admin foundation is secure but not operationally complete. A marketplace at Amazon/Noon style needs workflows, detail pages, command actions, monitoring, and cross-linked context so staff can resolve real marketplace problems without manual Firebase Console edits.

**Independent Test**: For each v2 operations module, tests prove the route exists, data reads are capped or paginated, actions execute through trusted backend commands, unauthorized roles are denied, and sensitive actions create immutable audit logs.

**Acceptance Scenarios**:

1. **Given** an admin opens `/dashboard`, **When** the page loads, **Then** they see command-center KPIs, operational alerts, queue shortcuts, and recent high-priority issues.
2. **Given** support searches for a buyer, order, or report, **When** they use global search, **Then** scoped results appear without exposing unrelated privileged data.
3. **Given** an admin opens a user, merchant, product, order, report, or ticket detail page, **When** they review the record, **Then** they can see linked context, history, notes, and allowed actions.
4. **Given** a sensitive action is submitted, **When** the backend command runs, **Then** the command validates role, target, transition, reason, and writes an immutable audit log.
5. **Given** a super_admin opens audit or staff management, **When** they filter activity or change staff access, **Then** the system shows role history and prevents unsafe escalation or last-super-admin removal.

### Edge Cases

- A user has `role == admin` in Firestore but no refreshed Custom Claims yet.
- A user has Custom Claims but their Firestore role document is missing, disabled, or downgraded.
- A moderator manually types a super_admin route URL.
- A support user attempts a direct write to product moderation or notifications.
- A public app deep link points to an old admin route.
- Firebase token refresh fails during login or role changes.
- Firestore rules and UI route permissions drift from each other.
- Admin Hosting accidentally points to the public app build output.
- Audit logs grow large and must remain searchable without unbounded reads.
- First super_admin bootstrap is attempted twice.
- A compromised admin account attempts to grant itself super_admin.
- A staff user's Custom Claims are stale after role revocation.
- Role metadata and token claims disagree.
- Audit log write fails during a role change.
- A staff user opens a v2 detail page without role permission for sensitive fields.
- A high-volume queue grows beyond a single page and must paginate without unbounded reads.
- A backend command succeeds in data update but audit write fails; the whole command must fail or rollback.
- A notification campaign targets too many users and must use capped preview plus backend fanout controls.
- An order/payment/support issue needs cross-linked context without leaking unrelated private data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a standalone Flutter Web admin console or separately built admin module outside the public buyer/seller mobile app.
- **FR-002**: Admin console MUST use the same Firebase project as the main Olmeg Connect app.
- **FR-003**: Admin console MUST provide its own login page, loading state, session validation, and Access Denied page.
- **FR-004**: Admin route access MUST require Firebase Custom Claims or an approved server-trusted role of `moderator`, `support`, `admin`, or `super_admin`.
- **FR-005**: Non-admin users MUST be denied protected admin routes and signed out or redirected away from the admin console.
- **FR-006**: Public mobile app MUST remove admin navigation, admin shell entries, and public admin routes.
- **FR-007**: Firestore Security Rules MUST enforce admin permissions independently from UI route hiding.
- **FR-008**: Role-based access control MUST include `moderator`, `support`, `admin`, and `super_admin`.
- **FR-009**: Admin console MUST include Dashboard, Users Management, Product Moderation, Reports, Merchant Verification, Notifications, and Audit Logs pages.
- **FR-010**: Moderator role MUST be limited to moderation and reports workflows.
- **FR-011**: Support role MUST be limited to reports/support workflows and read-only support context where needed.
- **FR-012**: Admin role MUST manage standard operations but MUST NOT manage super_admin-only role assignments or unrestricted audit controls.
- **FR-013**: Super_admin role MUST manage all admin pages, role assignments, and audit-log access.
- **FR-014**: Admin route structure MUST define each route, required roles, redirect behavior, and page ownership.
- **FR-015**: Firebase rules plan MUST define rule helper functions for role claims and collection-level permissions for users, products, reports, merchant verification, notifications, and audit logs.
- **FR-016**: Deployment plan MUST define separate Firebase Hosting targets for main app and admin panel.
- **FR-017**: Tests MUST verify non-admin denial, admin dashboard access, moderator-only moderation access, support-only reports/support access, and Firestore rule denial for unauthorized access.
- **FR-018**: Admin actions MUST write audit records for security-sensitive operations such as role changes, user bans, moderation decisions, merchant approvals, and notification campaigns.
- **FR-019**: Admin pages MUST avoid unbounded reads and use pagination, filtering, or capped queries for operational tables.
- **FR-019a**: Admin data tables MUST use capped queries by default and MUST NOT ship unbounded production collection reads.
- **FR-019b**: UI route guards MUST be treated only as a user experience layer; Firestore Rules and trusted Custom Claims are the authorization boundary.
- **FR-020**: Admin console MUST show a clear error state when role validation fails or rules reject an action.
- **FR-021**: System MUST define a trusted bootstrap process for creating the first super_admin account.
- **FR-022**: Only super_admin MUST be allowed to assign, revoke, disable, or escalate admin roles.
- **FR-023**: Role changes MUST update Firebase Custom Claims through a trusted backend/admin process, not through direct client writes.
- **FR-024**: Role changes MUST create immutable audit records that include actor, target, previous role, new role, reason, and timestamp.
- **FR-025**: Role permission details MUST explicitly define whether each role can read personal user fields, suspend products, ban users, approve merchants, send notifications, and read audit logs.
- **FR-026**: Admin operational tables MUST use pagination, filters, and documented indexes before release.
- **FR-027**: Firestore Rules tests MUST cover role lifecycle actions, stale claims behavior, and role escalation denial.
- **FR-028**: Firestore Rules MUST NOT trust mutable client-owned user document fields for admin authorization.
- **FR-029**: Reserved admin collections MUST NOT be reachable through broad fallback collection rules.
- **FR-030**: Admin console MUST evolve into a marketplace operations console following [admin-operations-v2-roadmap.md](./admin-operations-v2-roadmap.md).
- **FR-031**: Admin v2 MUST include global search across allowed users, merchants, products, orders, reports, support tickets, campaigns, and audit references.
- **FR-032**: Admin v2 MUST include detail pages or detail drawers for users, merchants, products, reports, orders, payments/refunds, support tickets, campaigns, audit logs, and staff.
- **FR-033**: Sensitive admin v2 actions MUST run through trusted backend commands instead of direct client-only Firestore writes.
- **FR-034**: Backend admin commands MUST validate actor role, target existence, allowed state transition, required reason, and audit-log creation.
- **FR-035**: Admin v2 MUST include order operations, returns/refunds/disputes, payment exception handling, support tickets, catalog/category management, marketing campaigns, risk review, analytics, and staff management.
- **FR-036**: Each admin v2 page MUST include search, filters, pagination/capped queries, empty/loading/error states, and role-specific action visibility.
- **FR-037**: Admin v2 command-center dashboard MUST use summary documents, aggregation functions, or capped reads and MUST NOT execute unbounded collection scans.

### Key Entities *(include if feature involves data)*

- **AdminUser**: Authenticated staff account with uid, email, display name, role, status, and claim sync state.
- **AdminRole**: Role value that controls route access and Firestore rule authorization: moderator, support, admin, super_admin.
- **AdminRoute**: Protected page route with required roles and redirect behavior.
- **AuditLog**: Immutable security-sensitive event record for admin actions.
- **ModerationItem**: Product, report, seller, merchant verification, or content item awaiting review.
- **HostingTarget**: Firebase Hosting target and build output for public app or admin console.
- **RoleAssignmentRequest**: Trusted request to assign, revoke, disable, or change an admin role, including actor, target, old role, new role, reason, and status.
- **BootstrapAdmin**: The first super_admin account created by a trusted one-time process.
- **AdminCommand**: Trusted backend action request that validates actor role, target, transition, reason, and audit requirements before mutating data.
- **AdminQueue**: Operational work queue such as moderation, merchant verification, reports, support tickets, refunds, failed payments, or risk cases.
- **AdminDetailView**: Full detail page or drawer that combines primary record data, linked context, notes, timeline, and allowed actions.
- **NotificationCampaign**: Marketing/admin communication campaign with audience, preview, send/schedule status, delivery counts, and audit trail.
- **SupportTicket**: Support workflow record linked to users, orders, merchants, products, reports, or payments.
- **RiskCase**: Trust and safety review record for suspicious users, merchants, products, payments, or activity patterns.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Non-admin users are denied 100% of protected admin routes in widget/router tests.
- **SC-002**: Admin and super_admin users can reach Dashboard in automated tests.
- **SC-003**: Moderator test user can access Product Moderation and Reports but is denied Users Management, Notifications, Merchant Verification, and Audit Logs.
- **SC-004**: Support test user can access Reports/support pages but is denied Product Moderation, Notifications, Merchant Verification, and Audit Logs.
- **SC-005**: Firestore rules emulator tests deny unauthorized reads/writes for admin collections and privileged admin actions.
- **SC-006**: Static scan confirms the public app has no visible admin navigation entry points.
- **SC-007**: Deployment documentation includes separate main and admin hosting targets, build commands, deploy commands, URLs, and rollback steps.
- **SC-008**: Admin operational pages use paginated or capped data access and do not introduce unbounded production reads.
- **SC-009**: Admin security QA checklist is completed before release.
- **SC-010**: First super_admin bootstrap can be executed once in a documented trusted process and cannot be repeated accidentally.
- **SC-011**: Only super_admin can assign or revoke admin roles in tests and Firestore rules checks.
- **SC-012**: Every role change and sensitive admin action creates an audit log record in tests or emulator verification.
- **SC-013**: Role permission matrix documents personal-data visibility and write capabilities for moderator, support, admin, and super_admin.
- **SC-014**: Every v2 operations page has search/filter controls and paginated or capped reads.
- **SC-015**: Every sensitive v2 command has tests proving unauthorized roles are denied and audit logs are written.
- **SC-016**: Admin command center shows at least six actionable marketplace KPIs or queue counts without unbounded reads.
- **SC-017**: Users, merchants, products, reports, orders, support tickets, campaigns, and audit logs each have a detail view contract before implementation.
- **SC-018**: Admin v2 release checklist verifies no sensitive workflow depends only on hidden UI buttons.

## Assumptions

- The preferred implementation is a separate Flutter Web app under `apps/admin_web` while the public app remains under the existing Flutter project root.
- The admin web app will reuse Firebase project configuration but have its own hosting target and build output.
- Custom Claims are the primary trust boundary for admin authorization; Firestore role documents may support display, workflow, and claim-sync checks but cannot replace server-trusted claims for privileged access.
- A privileged backend or secure admin process will be required to set and update Firebase Custom Claims.
- Existing admin screens in `lib/features/admin` can be migrated or reused only if they fit the separated admin app boundary.
- The first super_admin will be bootstrapped through a restricted script or backend-admin operation, not through the public app or unauthenticated UI.
- Implementation must finalize exact personal-data visibility before enabling support or moderator accounts in production.
