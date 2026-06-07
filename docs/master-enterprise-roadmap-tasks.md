# Olmeg Connect Enterprise Roadmap Tasks

This document cuts the master roadmap into executable phases and tasks.

Payment provider decision: Paymob only for the first production payment phase.
PayPal, Stripe, Apple Pay, and Google Pay are intentionally out of scope until
Paymob is stable in production.

Last updated: 2026-05-18

## Phase 0: Stop-the-Line Stabilization

Priority: Critical

Goal: make the current repository buildable, testable, and safe to continue.

Tasks:

- Fix `apps/admin_web/lib/core/monitoring/admin_error_reporter.dart` compile error.
- Fix admin route tests for moderator first route and navigation grouping.
- Pass `flutter analyze` from the repository root.
- Pass `flutter analyze` from `apps/admin_web`.
- Pass admin `flutter test`.
- Pass selected security and admin separation tests.
- Pass admin `flutter build web`.
- Add `functions/node_modules/` to `.gitignore`.
- Confirm no service-account JSON files are committed.

Exit gate:

- No compile errors.
- Admin Web Console can build.
- Security/admin separation tests pass.

## Phase 1: Production Security Lock

Priority: Critical

Goal: make Firebase security rules and backend operations safe before adding
more enterprise features.

Tasks:

- Replace broad Firestore fallback rules with deny-by-default.
- Add explicit Firestore rules for `chats`.
- Tighten `users` reads to avoid exposing user PII to all signed-in users.
- Add explicit field-level protections for `orders`, `payments`, and `notifications`.
- Require backend callable functions for user bans, merchant approvals, refunds, moderation, notifications, role changes, payment changes, and support escalation.
- Make sensitive audit logs backend-only.
- Add rule tests for direct client write denial.
- Add Storage rules for merchant verification documents readable by owner and authorized admin roles only.
- Add Storage file type and file size checks for all upload paths.

Exit gate:

- Direct client writes cannot perform sensitive state transitions.
- Reserved admin collections cannot fall through to broad rules.
- Chat and user data are not exposed through fallback rules.

## Phase 2: Admin Operations Stabilization

Priority: Very High

Goal: turn the current admin console from generic tables into reliable
operations workflows.

Tasks:

- Remove or formally quarantine legacy public-app admin screens under `lib/features/admin/`.
- Replace fake CSV export snackbar with real audit export pipeline or mark export disabled.
- Fix user restrict-post and mute-chat action payload mismatch.
- Add real cursor pagination to admin tables.
- Add server-side filters for users, products, reports, merchants, orders, refunds, payments, and support tickets.
- Add detail pages for users, merchants, products, reports, orders, refunds, payments, and support tickets.
- Add loading, empty, denied, and error states for every admin route.
- Add action visibility by role.
- Add audit history panels on detail pages.
- Add admin deployment checklist for every release.

Exit gate:

- Every admin route has real data, role checks, bounded queries, and production-safe actions.

## Phase 3: Analytics Foundation

Priority: High

Goal: create the event and analytics base before building dashboards.

Tasks:

- Define analytics event schema.
- Add client event tracking service.
- Track `app_opened`, `session_started`, `screen_viewed`, `product_viewed`, `search_started`, `checkout_started`, `payment_failed`, `chat_started`, `post_created`, and `report_submitted`.
- Add session ID generation.
- Add user journey event storage with privacy constraints.
- Add admin analytics summary documents.
- Add backend aggregation jobs for daily metrics.
- Add dashboard widgets for DAU, WAU, MAU, conversion, product views, cart starts, checkout starts, and order success.

Dashboard metric definitions:

- `DAU`: unique active users with at least one valid app/session event in a day.
- `WAU`: unique active users in the last seven days.
- `MAU`: unique active users in the last thirty days.
- `Product views`: count of valid `product_viewed` events.
- `Cart starts`: count of valid add-to-cart or cart-open events, finalized in the analytics spec.
- `Checkout starts`: count of valid `checkout_started` events.
- `Payment failures`: count of backend-confirmed failed Paymob payment attempts.
- `Order success`: count of orders moved to paid/confirmed by backend verification.
- `Conversion`: product-view to successful-order funnel rate.
- `Drop-off`: percentage of users leaving between two adjacent funnel steps.

Exit gate:

- Admin dashboard shows real analytics from event data, not only capped collection counts.

## Phase 4: Paymob Production Payment Infrastructure

Priority: Very High

Goal: implement production-grade payments using Paymob only.

Tasks:

- Create Paymob payment data model.
- Add Paymob configuration through secure environment/config storage.
- Create backend function to start Paymob payment intent/session.
- Create Paymob webhook Cloud Function.
- Verify webhook signatures/server authenticity.
- Map Paymob transaction status to internal payment states.
- Update order state only from backend verification.
- Add payment states: `pending`, `processing`, `paid`, `failed`, `refunded`, `disputed`.
- Add immutable payment audit logs.
- Add payment reconciliation records.
- Add admin payment operations page for failed payments, refunds, disputes, and recovery attempts.
- Add buyer payment success and failure screens.
- Add tests for webhook verification, duplicate webhook handling, failed payment, successful payment, and order update.

Out of scope:

- PayPal.
- Stripe.
- Apple Pay.
- Google Pay.
- Multi-provider abstraction.

Exit gate:

- Orders cannot become paid from client-side writes.
- Paymob webhook is the source of truth for payment confirmation.
- Admin can see and investigate payment failures.

## Phase 5: Fulfillment and Disputes

Priority: High

Goal: add real marketplace logistics and buyer/seller lifecycle tracking.

Tasks:

- Add order lifecycle states from `pending_payment` to `delivered`, `cancelled`, `refunded`, and `disputed`.
- Add seller order acceptance and rejection.
- Add seller tracking update workflow.
- Add buyer delivery timeline.
- Add delivery notes.
- Add refund request workflow.
- Add damaged product report workflow.
- Add delivery dispute workflow.
- Add admin mediation tools.

Exit gate:

- Buyer, seller, and admin see consistent order lifecycle state.

## Phase 6: Dynamic Notification Engine

Priority: High

Goal: move from manual capped sends to a real communication engine.

Tasks:

- Add audience segmentation.
- Add scheduled campaigns.
- Add recurring campaigns.
- Add timezone targeting.
- Add notification queue.
- Add dynamic triggers for payment success, order shipped, chat reply, product approved, saved search match, and price drop.
- Add campaign analytics for sent, opened, clicked, failed, and conversions.

Exit gate:

- Notifications are queued, measurable, and not limited to manual admin fanout.

## Phase 7: AI Moderation and Risk Engine

Priority: Very High

Goal: automate moderation and fraud detection after security and payment
foundation are stable.

Tasks:

- Define risk score model.
- Add risk signal extraction for text, price, seller history, reports, links, phone numbers, and duplicate listings.
- Add AI moderation service boundary.
- Add moderation result storage.
- Add review queue for medium/high risk content.
- Add dashboard risk reasons and highlighted evidence.
- Add backend-only AI moderation processing.
- Add tests for low, medium, and high risk flows.

Exit gate:

- AI can assist moderation without bypassing human/admin controls for high-risk actions.

## Phase 8: AI Marketplace Intelligence

Priority: High

Goal: make search, recommendations, and support smarter.

Tasks:

- Add semantic product search design.
- Select search infrastructure after Phase 2 pagination/filtering work.
- Add recommendation event inputs.
- Add buyer recommendation cards.
- Add seller optimization hints.
- Add support/admin assistant prototype.
- Add fraud pattern detection experiments.

Exit gate:

- AI features are measurable, explainable, and do not weaken security boundaries.

## Phase 9: Seller Ecosystem

Priority: Medium

Goal: make sellers professional operators, not just product uploaders.

Tasks:

- Add seller revenue dashboard.
- Add seller product views and conversion analytics.
- Add low stock alerts.
- Add boosted listings plan.
- Add sponsored products plan.
- Add merchant OCR verification plan.
- Add seller trust score.

Exit gate:

- Sellers can understand performance and improve operations from their dashboard.

## Phase 10: Performance and Scaling

Priority: Very High

Goal: prepare for high traffic and enterprise reliability.

Tasks:

- Add Crashlytics and Performance Monitoring.
- Add Cloud Functions error monitoring.
- Add backend job queue for expensive tasks.
- Add image thumbnail generation.
- Add CDN/image optimization strategy.
- Add Firestore read optimization plan.
- Add cache strategy for product discovery and admin dashboards.
- Add domain event model: `OrderPlacedEvent`, `PaymentSucceededEvent`, `ProductReportedEvent`, `MerchantApprovedEvent`, and `RefundRequestedEvent`.
- Add load testing plan.

Exit gate:

- The system has monitoring, queueing, and performance evidence before major scale targets.

## Execution Rule

Do not start Phase 4 Paymob production payments until Phase 0 and Phase 1 pass.

Do not start AI phases until admin, security, analytics, and payment foundations
are stable enough to produce trustworthy data.
