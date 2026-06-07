# Olmeg Connect Master Enterprise Roadmap

Complete strategic planning document for marketplace, AI, security, operations,
scaling, and enterprise evolution.

Last updated: 2026-05-30

## 1. Project Vision

Olmeg Connect should evolve into an AI-powered enterprise marketplace ecosystem.

The target platform combines:

- Marketplace commerce
- Social networking
- Seller management
- AI moderation
- Fraud prevention
- Real-time communication
- Enterprise analytics
- Smart recommendations
- Fulfillment and delivery
- Operations management
- Intelligent automation

Final goal: Olmeg Connect should become a scalable AI-powered marketplace
operating system, not only a Flutter marketplace app.

## 2. Current Project Position

Current strengths:

- Strong Flutter architecture with feature-first structure.
- Riverpod state management and GoRouter navigation.
- Reusable shared layers and widgets.
- Marketplace features: products, orders, cart, reviews, search, favorites, and seller system.
- Social layer: posts, feed, reactions, and comments.
- Communication layer: real-time chat, notifications, and Firebase Messaging.
- Admin foundation: separate Admin Web Console, RBAC, Firebase Claims, callable functions, and audit logs.

## 3. Current Critical Problems

These problems must be fixed before major expansion.

### Problem 1: System Instability

Current situation:

- Phase 0 validation now passes locally: root `flutter analyze`, admin `flutter analyze`, admin `flutter test`, public `flutter build web`, and admin `flutter build web`.
- This must stay enforced through CI/CD before the project can be treated as stable.

Risks:

- No stable deployment.
- QA instability.
- Hidden bugs.
- Broken CI/CD.

### Problem 2: Security Gaps

Current risks:

- Broad Firestore fallback has been replaced with deny-by-default and deployed.
- Direct client writes are still a risk in any workflow not yet moved behind callable functions.
- Storage rules now protect merchant documents, but upload paths still need emulator tests and production monitoring.
- Backend enforcement must continue expanding for remaining admin, support, refund, and moderation workflows.

### Problem 3: Admin Is Not Enterprise Yet

Current admin panel is mostly CRUD/table based.

Target admin system must become a marketplace operations intelligence center.

### Problem 4: Payment System Is Not Production Ready

Current status:

- Paymob is the only in-scope provider.
- Backend-created Paymob checkout sessions exist.
- Paymob webhook verification and reconciliation records exist.
- Firestore Rules block direct client writes to payment records.
- Remaining work: sandbox end-to-end evidence, duplicate webhook tests, refund/dispute flows, and production monitoring.

### Problem 5: No Real Analytics

Missing analytics areas:

- User journey analysis.
- Session tracking.
- Conversion analytics.
- Drop-off analysis.
- Behavior intelligence.

## 4. Enterprise Transformation Roadmap

## Phase 1: Production Foundation Lock

Priority: Critical

Goal: stabilize and secure the platform before adding new systems.

### 1.1 Build Stabilization

Required:

- Fix all compile errors.
- Fix failing tests.
- Pass root `flutter analyze`.
- Pass admin `flutter analyze`.
- Pass root and admin `flutter test`.
- Pass public app `flutter build web`.
- Pass admin app `flutter build web`.

Exit criteria:

- No compile errors.
- No failed tests in admin/security/public app separation suites.
- Admin hosting build artifact is generated successfully.

### 1.2 Firestore Security Hardening

Remove dangerous fallback rules.

Replace broad signed-in access patterns with deny-by-default behavior.

Explicit rules must exist for:

- `users`
- `chats`
- `products`
- `orders`
- `reviews`
- `notifications`
- `reports`
- `payments`
- `merchant_verifications`
- `support_tickets`
- `refunds`
- `promotions`
- `risk_cases`
- `admin_roles`
- `audit_logs`

Exit criteria:

- No top-level fallback allows arbitrary signed-in read/write.
- Sensitive collections cannot be modified directly by normal clients.
- Admin table queries are bounded by rule checks where supported.

### 1.3 Backend-Only Sensitive Operations

Never allow sensitive operations to rely on direct Flutter-to-Firestore writes.

Required flow:

Flutter UI to Cloud Function to validation to audit log to Firestore.

Sensitive operations:

- User bans.
- Merchant approvals.
- Refunds.
- Moderation decisions.
- Notifications.
- Role changes.
- Payment changes.
- Risk status changes.
- Support ticket escalation.

Exit criteria:

- Every sensitive action maps to a callable function.
- Firestore Rules reject direct client writes for those transitions.
- Every successful sensitive action creates an immutable audit log.

### 1.4 Audit Integrity

Requirements:

- Immutable logs.
- Backend-only sensitive action logs.
- Actor tracking.
- Role tracking.
- Reason required.
- Server timestamp validation.

Exit criteria:

- Admins cannot edit or delete audit logs.
- Normal clients cannot create audit logs.
- Backend command tests verify audit creation.

### 1.5 Storage Security

Add:

- File type restrictions.
- Size limits.
- User folder isolation.
- Secure admin access for merchant verification documents.
- Public read only where intentionally public.

Exit criteria:

- Merchant documents are readable by owner and authorized admin roles only.
- Product/review media upload limits are enforced.
- Catch-all storage rule is not overly public.

### 1.6 CI/CD Foundation

Add:

- GitHub Actions.
- Automated analyzer checks.
- Automated test checks.
- Public web build validation.
- Admin web build validation.
- Firebase deployment pipeline.

Exit criteria:

- Pull requests cannot merge if analyze/test/build fails.
- Admin and public hosting deploy independently.

## Phase 2: Enterprise Admin Ecosystem

Priority: Very High

Goal: transform the admin console into a marketplace operations center.

### 2.1 Analytics Dashboard

Metrics:

- DAU, WAU, MAU.
- Session duration.
- GMV.
- Order volume.
- Seller performance.
- Conversion rate.
- Failed payments.
- Refunds.
- Disputes.

### 2.2 User Journey Analytics

Track:

- Home to product view.
- Product view to add to cart.
- Add to cart to checkout.
- Checkout to payment.
- Payment to order success.

Detect:

- Drop-off points.
- Abandoned checkout.
- Low-conversion screens.

### 2.3 Marketplace Intelligence

Detect:

- Trending products.
- Inactive sellers.
- High-risk sellers.
- High-report categories.
- Fake product patterns.

### 2.4 Real Search Infrastructure

Current state:

- Local filtering over capped Firestore working sets.

Upgrade candidates:

- Algolia.
- Typesense.
- Elasticsearch/OpenSearch.

### 2.5 Real Pagination

Replace capped-only tables with:

- Cursor pagination.
- Infinite scrolling where appropriate.
- Indexed querying.
- Stable sorting.
- Server-side filters.

### 2.6 Support Operations System

Add:

- SLA tracking.
- Ticket assignment.
- Escalation flows.
- Support analytics.
- Linked user/order/product/report context.

## Phase 3: User Analytics and Feedback Intelligence

Priority: High

Goal: understand user behavior deeply.

### 3.1 Event Tracking System

Track:

- `app_opened`
- `session_started`
- `screen_viewed`
- `product_viewed`
- `search_started`
- `checkout_started`
- `payment_failed`
- `chat_started`
- `post_created`
- `report_submitted`

### 3.2 Session Analytics

Measure:

- Session duration.
- Retention.
- Screen exits.
- Navigation flow.
- Inactive users.

### 3.3 Funnel Analytics

Example funnel:

- Product view.
- Add to cart.
- Checkout.
- Payment.
- Success.

Track conversion between each step.

### 3.4 Feedback System

Users can submit:

- Bug reports.
- Payment issues.
- UI problems.
- Seller complaints.
- Feature requests.

### 3.5 Admin Feedback Dashboard

Show:

- Recurring complaints.
- App crashes.
- Feature requests.
- Low-rated experiences.

## Phase 4: Real Payment Infrastructure

Priority: Very High

Goal: build production-grade payment infrastructure.

### 4.1 Payment Providers

Current provider scope:

- Paymob.

Out of scope for now:

- PayPal.
- Stripe.
- Apple Pay.
- Google Pay.

Decision: build the first production payment infrastructure around Paymob only.
Other providers can be revisited after Paymob payments, webhooks,
reconciliation, refunds, and admin payment operations are stable.

### 4.2 Backend Payment Verification

Required flow:

- User pays.
- Payment provider processes payment.
- Provider sends webhook.
- Cloud Function verifies webhook.
- Payment record is updated.
- Order status is updated.
- Audit and reconciliation records are written.

### 4.3 Payment States

Required states:

- `pending`
- `processing`
- `paid`
- `failed`
- `refunded`
- `disputed`

### 4.4 Payment Operations Dashboard

Admin sees:

- Failed payments.
- Refunds.
- Fraud alerts.
- Disputes.
- Recovery attempts.

### 4.5 Escrow System

Goal: hold funds until product delivery and buyer confirmation.

Benefit: reduces fraud and protects both buyers and sellers.

## Phase 5: Delivery and Fulfillment System

Priority: High

Goal: enable real marketplace logistics.

### 5.1 Order Lifecycle

Required states:

- `pending_payment`
- `paid`
- `accepted_by_seller`
- `preparing`
- `ready_to_ship`
- `shipped`
- `out_for_delivery`
- `delivered`
- `cancelled`
- `refunded`
- `disputed`

### 5.2 Seller Fulfillment Dashboard

Seller can:

- Accept orders.
- Reject orders.
- Add tracking.
- Update status.
- Add notes.

### 5.3 Buyer Tracking Experience

Buyer sees:

- Timeline.
- Estimated delivery.
- Tracking code.
- Seller updates.

### 5.4 Delivery Models

Model A:

- Merchant handles delivery.

Model B:

- Integrated shipping providers.

### 5.5 Dispute System

Add:

- Refund requests.
- Damaged product reports.
- Delivery disputes.
- Admin mediation.

## Phase 6: Dynamic Notification Engine

Priority: High

Goal: create an enterprise communication system.

### 6.1 Manual Notification Campaigns

Admin targets:

- All users.
- Buyers.
- Sellers.
- Merchants.
- Inactive users.
- Abandoned cart users.
- Category-specific users.

### 6.2 Scheduled Notifications

Features:

- Send later.
- Recurring campaigns.
- Timezone targeting.

### 6.3 Dynamic Notifications

Examples:

- Payment success.
- Order shipped.
- Chat reply.
- Product approved.
- Saved search match.
- Price drop.

### 6.4 Campaign Analytics

Track:

- Sent.
- Opened.
- Clicked.
- Failed.
- Conversions.

## Phase 7: AI Moderation and Risk Engine

Priority: Very High

Goal: automate moderation intelligently.

### 7.1 Risk-Based Moderation

Flow:

- User submits content.
- AI calculates risk score.
- Low risk auto-publishes.
- Medium risk is monitored or reviewed.
- High risk is blocked or sent to review queue.

### 7.2 Risk Signals

Analyze:

- Blocked keywords.
- Scam language.
- Suspicious pricing.
- Seller history.
- Reports count.
- Image analysis.
- Duplicate listings.
- External links.
- Phone numbers.

### 7.3 Moderation Dashboard

Admin sees:

- Risk score.
- Reasons.
- Highlighted text.
- Seller history.
- Moderation actions.

### 7.4 AI Services

Recommended candidates:

- OpenAI Moderation.
- Google Gemini.
- AWS Rekognition.
- Vision APIs.

## Phase 8: AI Marketplace Intelligence

Priority: High

Goal: transform the marketplace into an AI-powered ecosystem.

### 8.1 AI Search

Example:

- User searches: "I want a cheap gaming laptop".
- AI understands intent, budget, category, and constraints.

### 8.2 AI Recommendations

Based on:

- Behavior.
- Purchases.
- Searches.
- Favorites.
- Chats.

### 8.3 AI Assistant

Helps:

- Buyers.
- Sellers.
- Support staff.

### 8.4 AI Fraud Detection

Detect:

- Fake accounts.
- Scam sellers.
- Fake reviews.
- Suspicious payments.

## Phase 9: Seller Ecosystem

Priority: Medium

Goal: create a professional seller platform.

### 9.1 Seller Analytics

Show:

- Revenue.
- Views.
- Conversion.
- Top products.
- Low stock.

### 9.2 Promotions System

Add:

- Boosted listings.
- Sponsored products.
- Campaigns.

### 9.3 Merchant Verification

Add:

- ID verification.
- OCR.
- Trust scores.
- Business documents.

## Phase 10: Performance and Scaling

Priority: Very High

Goal: prepare for large-scale traffic.

### 10.1 Cloud Functions Expansion

Add:

- Background jobs.
- AI processing.
- Cleanup jobs.
- Notification queue.

### 10.2 Caching Layer

Add:

- Local cache.
- Redis or equivalent cache where justified.
- Firestore read optimization.

### 10.3 CDN Optimization

Optimize:

- Product images.
- Thumbnails.
- Feed media.

### 10.4 Monitoring

Add:

- Crashlytics.
- Performance Monitoring.
- Error tracking.
- Server monitoring.

### 10.5 Event-Driven Architecture

Add domain events:

- `OrderPlacedEvent`
- `PaymentSucceededEvent`
- `ProductReportedEvent`
- `MerchantApprovedEvent`
- `RefundRequestedEvent`

## 5. Design and UX Evolution

Goal: upgrade UI from developer UI to premium marketplace experience.

Improve:

- Visual hierarchy.
- Typography.
- Motion.
- Interaction quality.
- Product pages.
- Feed immersion.
- Chat UX.

Keep:

- Neon green identity.
- Dark theme.
- Rounded style.
- Marketplace personality.

## 6. Recommended Sprint Order

| Sprint | Focus | Required outcome |
|---|---|---|
| 1 | Production stabilization | Builds, analyzer, and critical tests pass. |
| 2 | Security hardening | Firestore/Storage deny-by-default and backend-only sensitive writes. |
| 3 | Admin ecosystem stabilization | Admin pages become reliable operations tools, not placeholders. |
| 4 | Analytics foundation | Event tracking, session tracking, and first admin analytics. |
| 5 | Payment infrastructure | Provider webhooks, backend verification, reconciliation. |
| 6 | Delivery system | Order lifecycle, seller fulfillment, buyer tracking. |
| 7 | Notification engine | Campaigns, scheduling, dynamic triggers, analytics. |
| 8 | AI moderation | Risk scoring and moderation dashboard. |
| 9 | AI recommendations/search | Semantic search and recommendation services. |
| 10 | Scaling and enterprise optimization | Monitoring, caching, queues, event-driven architecture. |

## 7. Non-Negotiable Engineering Rules

Do not:

- Add random features without tying them to a phase.
- Redesign everything at once.
- Add AI before stabilization.
- Trust the Flutter client for security-sensitive actions.
- Ship direct sensitive Firestore writes.

Always:

- Prioritize backend validation.
- Protect Firestore rules.
- Use callable functions for sensitive operations.
- Log sensitive actions.
- Monitor behavior.
- Build incrementally.
- Prove each phase with tests and deployment checks.

## 8. Immediate Action Plan

The next implementation work should start here:

1. Remove or quarantine legacy public-app admin code under `lib/features/admin/`.
2. Finish Admin Operations Phase 2: cursor pagination, server-side filters, audit export, audit history panels, and role-aware action visibility.
3. Add Paymob sandbox tests for success, failure, duplicate webhook, refund, and dispute scenarios.
4. Add CI checks for root app, admin app, rules tests, and web builds.
5. Add analytics/session/funnel implementation after the foundation gates remain green.

## 9. Spec Kit Mapping

Existing Spec Kit features:

- `specs/002-admin-web-console/`
- `specs/003-enterprise-roadmap/`
- `specs/005-analytics-and-feedback-intelligence/`
- `specs/006-paymob-production-payment-infrastructure/`
- `specs/007-fulfillment-and-disputes/`
- `specs/008-dynamic-notification-engine/`
- `specs/009-ai-moderation-risk-engine/`
- `specs/010-ai-marketplace-intelligence/`
- `specs/011-seller-ecosystem/`
- `specs/012-performance-scaling/`
- `005-analytics-and-feedback-intelligence`
- `006-paymob-production-payment-infrastructure`
- `007-fulfillment-and-disputes`
- `008-dynamic-notification-engine`
- `009-ai-moderation-risk-engine`
- `010-ai-marketplace-intelligence`
- `011-seller-ecosystem`
- `012-performance-scaling`

Each feature should include:

- `spec.md`
- `plan.md`
- `tasks.md`
- Firebase rules plan where relevant.
- Data model changes.
- Test plan.
- Deployment and rollback plan.
