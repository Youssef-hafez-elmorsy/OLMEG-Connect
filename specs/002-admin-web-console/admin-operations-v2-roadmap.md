# Admin Operations Console v2 Roadmap

## Vision

Olmeg Admin must become a full marketplace operations console comparable to large e-commerce platforms such as Amazon, Noon, Shopify marketplace operations, and modern seller-center back offices. The console must support daily operations, incident response, growth campaigns, fraud/risk review, merchant onboarding, buyer support, catalog quality, payments, fulfillment, and executive monitoring.

The admin web app is not just a list of collections. It must be an operational command system with role-based workflows, backend-enforced actions, immutable audit trails, capped queries, searchable queues, detail pages, and dashboards that let the team run the marketplace safely.

## Non-Negotiable Principles

- Sensitive actions must execute through trusted backend commands, preferably Firebase Callable Functions using Firebase Admin SDK.
- UI route guards are only a user experience layer; backend functions, Custom Claims, and Firestore Rules are the security boundary.
- Every sensitive action must require a reason and create an immutable audit log.
- Operational tables must use filters, pagination, capped queries, and documented indexes.
- Admin pages must show action status, errors, retry options, and audit references.
- Every major queue must have detail views, not only table rows.
- Admin must support English-first UI now and be ready for Arabic/localization later.
- No admin workflow should require editing Firestore manually from Firebase Console.

## Target Information Architecture

### Global Shell

- Command-center dashboard
- Global search across users, merchants, products, orders, reports, and campaigns
- Role-aware navigation
- Quick actions menu
- Notifications/alerts inbox for staff
- Breadcrumbs and deep links
- Detail drawer pattern for fast review
- Full detail pages for complex workflows

### Main Sections

| Section | Purpose |
|---------|---------|
| Command Center | Marketplace KPIs, alerts, live queues, growth/risk health |
| Users | Buyer/seller profiles, account status, restrictions, history |
| Merchants | Verification, store quality, seller performance, payouts readiness |
| Catalog | Products, categories, attributes, media, quality rules |
| Moderation | Product/report/review queues and escalation workflows |
| Orders | Order search, status issues, returns, disputes, fulfillment exceptions |
| Payments | Payment attempts, refunds, payout status, reconciliation |
| Support | Tickets, user issues, SLA queues, internal notes |
| Marketing | Notifications, campaigns, promotions, banners, coupons |
| Risk | Fraud signals, abusive accounts, suspicious activity, velocity limits |
| Analytics | Trends, cohorts, conversion, merchant/product performance |
| Audit Logs | Immutable admin activity search and export |
| Staff & Roles | Admin invitations, RBAC, staff disablement, role history |
| Settings | Marketplace policies, category rules, operational thresholds |

## Route Map

| Route | Page | Roles |
|-------|------|-------|
| `/dashboard` | Command Center | admin, super_admin |
| `/search` | Global Admin Search | support, admin, super_admin |
| `/users` | Users Queue | admin, super_admin |
| `/users/:userId` | User Detail | support, admin, super_admin with scoped fields |
| `/merchants` | Merchant Verification Queue | admin, super_admin |
| `/merchants/:merchantId` | Merchant Detail | admin, super_admin |
| `/catalog/products` | Product Catalog | moderator, admin, super_admin |
| `/catalog/products/:productId` | Product Detail | moderator, admin, super_admin |
| `/catalog/categories` | Category Management | admin, super_admin |
| `/moderation/products` | Product Moderation Queue | moderator, admin, super_admin |
| `/moderation/reviews` | Review Moderation Queue | moderator, admin, super_admin |
| `/reports` | Reports Queue | moderator, support, admin, super_admin |
| `/reports/:reportId` | Report Detail | moderator, support, admin, super_admin |
| `/orders` | Orders Operations | support, admin, super_admin |
| `/orders/:orderId` | Order Detail | support, admin, super_admin |
| `/payments` | Payment Operations | admin, super_admin |
| `/refunds` | Refund/Return Operations | support, admin, super_admin |
| `/support/tickets` | Support Tickets | support, admin, super_admin |
| `/marketing/notifications` | Notification Campaigns | admin, super_admin |
| `/marketing/promotions` | Promotions & Coupons | admin, super_admin |
| `/risk` | Risk Dashboard | admin, super_admin |
| `/analytics` | Marketplace Analytics | admin, super_admin |
| `/audit-logs` | Audit Logs | super_admin |
| `/staff` | Staff & Role Management | super_admin |
| `/settings` | Operations Settings | super_admin |

## Phase Plan

### Phase A - Admin Product Definition and Design System

Goal: Make the admin console feel like a real e-commerce operations product.

Deliverables:
- Admin design system: layout grid, table patterns, filters, drawers, forms, status chips, action bars, destructive action dialogs.
- Shared admin components: `AdminScaffold`, `AdminDataGrid`, `AdminDetailDrawer`, `AdminActionDialog`, `AdminStatusBadge`, `AdminMetricCard`.
- Navigation model for all v2 routes.
- Empty/loading/error/skeleton states.
- Accessibility baseline for keyboard and screen-reader navigation.

Exit criteria:
- All future admin pages use shared components.
- No page ships as a placeholder table-only view.

### Phase B - Backend Command Layer

Goal: Move sensitive actions from direct client Firestore writes to backend commands.

Deliverables:
- Firebase Callable Functions for all sensitive admin actions.
- Role enforcement in functions using Custom Claims.
- Function-level validation for required reason, target id, allowed transitions, and actor role.
- Immutable audit log write in the same trusted command path.
- Typed client command wrapper in admin web app.
- Function tests for authorization and audit requirements.

Initial callable commands:
- `adminBlockUser`
- `adminUnblockUser`
- `adminRestrictUserPosting`
- `adminMuteUserChat`
- `adminSoftDeleteUser`
- `adminApproveMerchant`
- `adminRejectMerchant`
- `adminSuspendMerchant`
- `adminApproveProduct`
- `adminRejectProduct`
- `adminHideProduct`
- `adminEscalateProduct`
- `adminResolveReport`
- `adminDismissReport`
- `adminEscalateReport`
- `adminCreateNotificationCampaign`
- `adminCancelNotificationCampaign`
- `adminAssignStaffRole`
- `adminDisableStaff`

Exit criteria:
- UI no longer performs sensitive writes directly.
- Every command test proves unauthorized roles are denied.
- Every command writes audit logs.

### Phase C - Command Center Dashboard

Goal: Give operators a real marketplace control room.

Deliverables:
- KPI cards: active users, new users, active merchants, pending merchants, active products, pending moderation, open reports, open support tickets, orders today, GMV estimate, failed payments, refunds pending.
- Alert panel: high-severity reports, payment failures, suspicious account spikes, seller SLA breaches.
- Queue shortcuts: moderation, merchants, reports, support, refunds.
- Time-range filters: today, 7 days, 30 days.
- Role-specific dashboard views.

Exit criteria:
- Admin can see what needs action in under 10 seconds.
- Dashboard queries are capped, aggregated, or backed by summary docs.

### Phase D - Users Operations

Goal: Make user management usable for support and trust/safety.

Deliverables:
- Search by email, uid, phone, display name.
- Filters: status, account type, merchant status, created date, risk flags.
- User detail page with profile, orders, products, reports, tickets, notifications, activity timeline.
- Actions: block/unblock, restrict posting, mute chat, soft delete, restore, add internal note.
- Risk indicators: many reports, failed payments, suspicious activity, duplicate devices when available.

Exit criteria:
- An admin can investigate and act on a user without leaving the admin console.

### Phase E - Merchant and Seller Operations

Goal: Support marketplace seller onboarding and ongoing seller quality.

Deliverables:
- Merchant verification queue with filters and detail review.
- Merchant detail page: documents, store profile, product count, order performance, report count, payout readiness.
- Actions: approve, reject, suspend, restore, request more info, add note.
- Seller quality score inputs and delivery eligibility.
- Seller product sync after verification status changes.

Exit criteria:
- Merchant approval/rejection is fully auditable and updates all dependent user/product status fields.

### Phase F - Catalog and Product Operations

Goal: Manage the marketplace catalog like a large e-commerce platform.

Deliverables:
- Product catalog search with status/category/seller filters.
- Product detail page with images, seller, category, pricing, inventory, moderation history.
- Category management: category list, subcategories, visibility, sort order, icon/image, commission/delivery rules if needed.
- Bulk actions: hide products, reassign category, flag for review.
- Media quality checks and missing data warnings.

Exit criteria:
- Admin can correct catalog quality without using Firebase Console.

### Phase G - Moderation Center

Goal: Give moderators high-throughput queues.

Deliverables:
- Product moderation queue with severity, reason, seller risk, image preview.
- Review moderation queue.
- Report moderation queue grouped by target.
- Detail review with previous actions and linked user/product/order context.
- Actions: approve, reject, hide, escalate, resolve, dismiss, assign.
- Internal notes and moderation history.

Exit criteria:
- Moderator can process queues quickly and safely with audit trails.

### Phase H - Orders, Returns, and Disputes

Goal: Add e-commerce operations workflows beyond catalog/admin basics.

Deliverables:
- Order search by order id, buyer, seller, status, date.
- Order detail page: buyer, seller, items, payment status, shipment/status timeline.
- Exception queues: cancelled, delayed, refund requested, return requested, payment failed.
- Actions: open support ticket, mark issue resolved, escalate refund, add internal note.
- Link reports and tickets to orders.

Exit criteria:
- Support can investigate order problems from one page.

### Phase I - Payments, Refunds, and Reconciliation

Goal: Make money operations visible and controlled.

Deliverables:
- Payment attempts table.
- Failed payments queue.
- Refund requests queue.
- Payout readiness/status for merchants.
- Reconciliation status indicators.
- Actions: flag payment, approve refund request, escalate finance review, add finance note.

Exit criteria:
- Finance/admin can see payment problems without direct Firestore queries.

### Phase J - Support Desk

Goal: Create a support workflow, not just reports.

Deliverables:
- Ticket queue with SLA, priority, category, assignee, status.
- Ticket detail page with user/order/product context.
- Internal notes and status changes.
- Assignment workflow.
- Support macros/templates for common responses.

Exit criteria:
- Support role can handle issues without access to unrelated privileged pages.

### Phase K - Marketing and Growth Tools

Goal: Add controlled campaign management like major marketplaces.

Deliverables:
- Notification campaign builder: audience, preview, test send, schedule/send now.
- Campaign history and delivery stats.
- Promotions/coupons manager.
- Home banners and featured marketplace picks manager.
- Audience filters: all, buyers, merchants, inactive users, handmade buyers, new users.

Exit criteria:
- Admin can launch campaigns safely with preview, targeting, and audit logs.

### Phase L - Risk and Trust Dashboard

Goal: Detect abuse before it hurts the marketplace.

Deliverables:
- Risk queue for suspicious users, sellers, products, and payments.
- Signals: report velocity, duplicate account indicators, failed payments, product rejection rate, spammy posting.
- Actions: restrict, escalate, add watchlist, remove watchlist.
- Watchlist and case timeline.

Exit criteria:
- Admin can find and act on risky accounts from one area.

### Phase M - Audit, Compliance, and Exports

Goal: Make admin activity reviewable and exportable.

Deliverables:
- Audit log filters: actor, role, action, target type, target id, date range.
- Audit detail view with metadata.
- Export CSV for super_admin.
- Tamper-evident append-only policy documentation.
- High-risk action alerts.

Exit criteria:
- Super_admin can answer: who did what, when, why, and to which object.

### Phase N - Staff and Role Management

Goal: Manage admin team access without scripts for normal operations.

Deliverables:
- Staff list.
- Invite staff by email.
- Assign moderator/support/admin roles through backend command.
- Disable/re-enable staff.
- Role history and audit trail.
- Prevent self-escalation and unsafe last-super-admin removal.

Exit criteria:
- Only super_admin can manage staff; no role change happens without Custom Claims update and audit log.

### Phase O - Analytics and Business Intelligence

Goal: Provide marketplace health insights.

Deliverables:
- Revenue/GMV summaries.
- Product/category performance.
- Seller performance.
- Buyer activity cohorts.
- Conversion funnel where available.
- Export summary reports.

Exit criteria:
- Admin can review business health without manual database analysis.

### Phase P - Observability, QA, and Hardening

Goal: Make the admin console production-safe.

Deliverables:
- Error reporting for admin web.
- Function error logs and alerting.
- Performance checks for all major pages.
- Firestore index coverage.
- Role matrix test suite.
- Callable function authorization tests.
- E2E smoke test for every route.
- Load test for dashboard and high-use queues.

Exit criteria:
- Every release has automated security, route, function, and performance evidence.

## Implementation Priority

1. Phase A - Admin product foundation and shared UI components.
2. Phase B - Backend command layer.
3. Phase C - Command center dashboard.
4. Phase D - Users operations.
5. Phase E - Merchant and seller operations.
6. Phase G - Moderation center.
7. Phase J - Support desk.
8. Phase K - Marketing and growth tools.
9. Phase H - Orders, returns, and disputes.
10. Phase I - Payments and refunds.
11. Phase F - Catalog and category operations.
12. Phase M - Audit and exports.
13. Phase N - Staff and roles.
14. Phase L - Risk dashboard.
15. Phase O - Analytics.
16. Phase P - Observability and hardening.

## Definition of Done for a Big E-Commerce Admin Page

Each admin page is only complete when it has:

- Search
- Filters
- Pagination or capped queries
- Status tabs or queue segmentation
- Detail drawer/page
- Primary and secondary actions
- Required reason for sensitive actions
- Backend command enforcement
- Immutable audit log
- Empty/loading/error states
- Role-specific access behavior
- Tests for allowed and denied roles
- Index documentation
- QA checklist entry
