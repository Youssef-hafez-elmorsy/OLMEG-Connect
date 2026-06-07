# Feature Specification: Amazon-Style Marketplace Experience

**Feature Branch**: `001-amazon-style-marketplace`  
**Created**: 2026-05-11  
**Status**: Draft  
**Input**: User description: "I want my Flutter marketplace app to become like Amazon"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Buyer Shopping Journey (Priority: P1)

A buyer can open the app, discover products through a commerce-first home screen, search and filter listings, inspect product details, add products to cart, and complete checkout with confidence.

**Why this priority**: This is the core marketplace value. Without a strong buyer journey, seller tools and admin controls do not create business value.

**Independent Test**: A signed-in buyer can start from home, find a product, add it to cart, review totals, select an address, and create an order.

**Acceptance Scenarios**:

1. **Given** an authenticated buyer, **When** they open home, **Then** they see categories, featured deals, recommended products, and recently viewed products.
2. **Given** a buyer searching for a product, **When** they use search filters and sorting, **Then** results update by category, price, rating, condition, availability, and sort order.
3. **Given** a product detail page, **When** the buyer views it, **Then** they see images, price, variants, stock state, seller info, ratings, return policy, related products, and delivery information only when the seller is an approved merchant.
4. **Given** cart items are available in stock, **When** the buyer checks out, **Then** the app creates an order with an auditable order status.

---

### User Story 2 - Seller Operations (Priority: P2)

A seller can create listings, manage inventory, see incoming orders, update fulfillment states, and communicate with buyers.

**Why this priority**: A marketplace needs reliable seller operations to keep product availability, shipping status, and buyer trust accurate.

**Independent Test**: A seller can publish a product, receive a buyer order, update the order status, and see the buyer notified.

**Acceptance Scenarios**:

1. **Given** an authenticated seller, **When** they open seller tools, **Then** they can view listings, inventory status, and order queue.
2. **Given** a seller has an order, **When** they update it to preparing, shipped, or delivered, **Then** the buyer sees the updated status.
3. **Given** a listing is out of stock, **When** a buyer attempts checkout, **Then** the buyer is prevented from placing an invalid order.

---

### User Story 3 - Trust, Reviews, and Moderation (Priority: P3)

Buyers, sellers, and admins can rely on reviews, moderation, reporting, and marketplace policies to reduce fraud and low-quality listings.

**Why this priority**: Trust improves conversion and retention, but the initial MVP can still function before every trust signal is complete.

**Independent Test**: A completed buyer can review a product, another user can report suspicious content, and an admin can resolve the report.

**Acceptance Scenarios**:

1. **Given** a buyer has a delivered order, **When** they submit a review, **Then** the review is tied to the product, seller, buyer, and order.
2. **Given** a user reports a product, review, seller, or post, **When** an admin opens moderation, **Then** the report appears in a reviewable queue.
3. **Given** an admin rejects a product, **When** buyers search or browse, **Then** the rejected product is hidden from public commerce surfaces.

---

### User Story 4 - Full App QA Stabilization (Priority: P1)

A buyer, seller, admin, or guest can tap primary app buttons, open shared links, navigate product/chat/order flows, and use purchase-related screens without crashes, dead taps, or misleading placeholder behavior.

**Why this priority**: The app currently passes static analysis and unit tests, but broad QA found runtime-flow risks that users experience as "many errors": deep-link route crashes, empty button handlers, weak UI regression coverage, and checkout/payment wording that can mislead users.

**Independent Test**: Run analyzer, unit/widget tests, web build, and targeted navigation/widget tests covering product detail, chat detail, cart, checkout, profile, settings, and admin/seller entry points.

**Acceptance Scenarios**:

1. **Given** a product, chat, or order URL is opened directly or refreshed on web, **When** the route loads without `state.extra`, **Then** the app shows a loading, not-found, or recovery state instead of crashing.
2. **Given** a user taps a visible settings/profile/chat action, **When** the feature is not implemented, **Then** the app either navigates to a real screen, performs the action, or clearly explains that the feature is unavailable.
3. **Given** a buyer uses cart and checkout, **When** they place or recover an order, **Then** labels and disabled states accurately describe whether payment is pending, simulated, external, or complete.
4. **Given** primary screens are tested in English and Arabic, **When** UI smoke tests run, **Then** critical buttons remain tappable and no primary layout throws an exception.

---

### User Story 5 - Modern Buyer UI/UX Refresh (Priority: P1)

A buyer experiences a polished modern marketplace journey with a stronger home entry point, clearer product cards, trust-forward product details, and checkout screens that communicate progress, totals, and next actions with confidence.

**Why this priority**: The app is feature-rich, but the buyer journey needs stronger visual hierarchy and clearer interaction design so users can browse, compare, and buy without feeling lost.

**Independent Test**: A buyer can open home, scan product sections, open product detail, add a delivery-eligible product to cart, review checkout, and understand the final action without layout overflow or unclear calls to action.

**Acceptance Scenarios**:

1. **Given** a buyer opens home, **When** products and sections load, **Then** the screen presents a clear marketplace hero, search/action entry points, category/deal sections, and responsive product grids.
2. **Given** a buyer scans products, **When** they compare cards, **Then** price, discount, stock, delivery eligibility, rating, seller trust, and visitor signals are visually scannable.
3. **Given** a buyer opens product detail, **When** they review purchase information, **Then** delivery eligibility, seller contact guidance, trust/safety, and related products are grouped with clear hierarchy.
4. **Given** a buyer reviews cart and checkout, **When** they are blocked or ready to place an order, **Then** the UI explains the state and highlights the next best action.

---

### User Story 6 - Performance and Capacity Readiness (Priority: P1)

A marketplace operator can understand how many users the app can safely support, and buyers/sellers can keep using product discovery, chat, checkout, and primary navigation without excessive read usage, write contention, or quota surprises.

**Why this priority**: Current capacity is limited less by Flutter UI and more by Firebase usage patterns. Product browsing, chat listeners, screen telemetry, and product view counters must be measured and optimized before production traffic grows.

**Independent Test**: Run analyzer, tests, web build, Firestore query review, and a documented capacity checklist that estimates home, product detail, chat, checkout, and notification read/write cost per active user.

**Acceptance Scenarios**:

1. **Given** many buyers open the marketplace home screen, **When** product sections load, **Then** the app uses bounded server-side queries or documented capped listeners instead of unbounded client filtering.
2. **Given** a user opens their chat inbox, **When** conversations load, **Then** only conversations involving that user are listened to or read.
3. **Given** many users open the same product, **When** view analytics are recorded, **Then** the app avoids high-frequency writes to a single product document.
4. **Given** screen performance telemetry is enabled, **When** traffic increases, **Then** telemetry writes are sampled, batched, disabled for production client traffic, or moved behind a safe aggregation path.
5. **Given** the app is deployed to Firebase Hosting, **When** the team reviews launch readiness, **Then** the expected daily active users, concurrent users, Firestore reads/writes, and Hosting transfer are documented with free-plan and paid-plan assumptions.

---

### User Story 7 - 100k Concurrent User Scale Target (Priority: P1)

A marketplace operator can prepare Olmeg Connect for a staged path toward 100,000 concurrent active users by separating high-traffic read models, write aggregation, search, media delivery, monitoring, and load testing from the current direct-client Firestore MVP architecture.

**Why this priority**: 100k concurrent users is not a small tuning goal. It requires production architecture, paid infrastructure, traffic ramping, cost controls, observability, and proof through load tests before public launch at that size.

**Independent Test**: A scale-readiness review can show documented target traffic assumptions, a staged load-test plan, cache/search/feed architecture, sharded counters or aggregation for hot metrics, quota/cost alerts, and pass/fail criteria for 10k, 25k, 50k, and 100k concurrent-user stages.

**Acceptance Scenarios**:

1. **Given** 100k concurrent buyers browse home and category surfaces, **When** traffic ramps gradually, **Then** the app serves most catalog discovery from cached or precomputed read models instead of every client opening expensive live product listeners.
2. **Given** a product becomes viral, **When** thousands of users view, favorite, or message about it, **Then** counters, analytics, and notifications are distributed or queued so no single document or narrow key range becomes a hotspot.
3. **Given** catalog size and search traffic grow, **When** buyers search or filter, **Then** the app uses a dedicated search/index strategy or denormalized query model rather than only client-composed Firestore queries.
4. **Given** the web app receives a large launch spike, **When** users load static assets and product images, **Then** CDN caching, immutable asset headers, optimized images, and cache budgets protect Hosting transfer and app startup time.
5. **Given** the team wants to claim 100k readiness, **When** release gates run, **Then** staged load tests, monitoring dashboards, alert thresholds, rollback steps, and cost estimates must pass before production rollout.

### Edge Cases

- Product price, stock, or status changes after an item is added to cart.
- Buyer taps place order more than once because of network delay.
- Payment succeeds but client loses network before order confirmation is displayed.
- Seller attempts to update an order that belongs to another seller.
- Buyer attempts to review a product without a completed order.
- Arabic locale requires right-to-left layout and localized commerce labels.
- Firestore query requires a missing composite index.
- Product or chat routes are opened from a copied link, notification, or browser refresh without in-memory navigation extras.
- A visible icon/menu action exists before its backing feature is implemented.
- Product cards contain long localized labels, large prices, missing images, or mixed delivery eligibility states.
- Buyer screens are opened on wide web/desktop windows where full-width mobile layouts would feel stretched.
- Traffic spikes after promotion, social sharing, or seller campaign launch.
- Many users open the same popular product in a short time window.
- Chat inbox contains more than the latest global conversation limit.
- Free Firebase quota is exhausted before the end of the day.
- Performance telemetry or analytics writes fail and must not block the user experience.
- A public campaign sends traffic faster than the backend can auto-split or warm up.
- A small set of products, chats, counters, or notification targets receives disproportionate traffic.
- Static web assets or images are repeatedly downloaded because cache headers or asset versioning are wrong.
- Search traffic exceeds what Firestore query composition can support economically.
- Load testing passes at 10k but reveals cost, latency, or error-rate problems before 100k.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a commerce-first home screen with categories, featured deals, recommendations, recently viewed products, and top-rated products.
- **FR-002**: System MUST support product search with filters for category, price range, condition, rating, seller, availability, and sort order.
- **FR-003**: Product details MUST show image gallery, title, description, price, sale price, stock state, variants, seller information, rating summary, reviews, return policy, and related products. Delivery estimate or delivery actions MUST appear only for products sold by approved merchant accounts.
- **FR-004**: Buyers MUST be able to add products to cart, update quantities, remove products, save products for later, and favorite products.
- **FR-005**: Checkout MUST support address selection, approved-merchant delivery guidance, payment method selection, order summary, and final order confirmation. For products not sold by approved merchants, buyers MUST be directed to contact the seller outside the in-app delivery flow.
- **FR-006**: Orders MUST support statuses for pending payment, paid, preparing, shipped, delivered, cancelled, and refunded.
- **FR-007**: Buyers MUST be able to view order history and order details.
- **FR-008**: Sellers MUST be able to manage listings, inventory, order fulfillment status, and buyer conversations.
- **FR-009**: Admins MUST be able to moderate products, users, sellers, reviews, reported content, and promotional placements.
- **FR-010**: Notifications MUST cover order updates, chat messages, price changes, moderation actions, and promotions.
- **FR-011**: Reviews MUST support product-level and seller-level feedback, with verified-purchase status when available.
- **FR-012**: User-facing commerce flows MUST support English and Arabic localization.
- **FR-013**: Analytics MUST record search, product view, add to cart, checkout started, order placed, favorite, review submitted, and seller actions.
- **FR-014**: Firestore security rules MUST restrict user-owned data, seller-owned inventory, admin-only moderation, and private order access.
- **FR-015**: Add-to-cart and checkout actions MUST appear only when the product is delivery-eligible through an approved merchant account. Products from regular users or unverified sellers MUST guide buyers to contact the seller instead.
- **FR-016**: Product delivery eligibility MUST be limited to approved merchant accounts. Regular users, unverified sellers, rejected merchants, and suspended merchants MUST never expose address checkout, delivery estimates, delivery tracking, or delivery fee calculation.
- **FR-017**: New account registration MUST eventually ask whether the user is a regular user or merchant. Merchant registration MUST collect tax ID, business address, and required business verification details. This merchant onboarding work is deferred to Phase 7.
- **FR-018**: Product and chat detail routes MUST handle direct URL entry, refresh, notification links, and missing navigation extras without runtime casts or crashes.
- **FR-019**: User-visible buttons, menu items, and icon actions MUST not use empty handlers. If a feature is deferred, the UI MUST show a clear unavailable/coming-soon message or hide the action.
- **FR-020**: Checkout and payment screens MUST use copy and button states that accurately describe whether payment is pending, simulated, external, recovered, or completed.
- **FR-021**: Critical buyer, seller, admin, chat, profile, settings, English, and Arabic flows MUST have automated smoke coverage or a documented manual QA checklist before release.
- **FR-022**: Buyer-facing home, product card, product detail, cart, and checkout surfaces MUST use a consistent modern marketplace visual language with clear hierarchy, trust signals, and responsive constraints.
- **FR-023**: Product cards MUST make sale price, original price, stock state, delivery eligibility, rating, seller trust, and visitor count easy to scan without overflow.
- **FR-024**: Buyer checkout surfaces MUST present address, delivery, payment, items, totals, and disabled-state reasons in a visually grouped and accessible way.
- **FR-025**: Buyer UI updates MUST preserve English/Arabic compatibility and avoid layout overflow on mobile and web widths.
- **FR-026**: Product discovery, category browsing, and recommendations MUST use bounded reads with documented limits and avoid accidental unbounded client-side filtering for production surfaces.
- **FR-027**: Chat inbox loading MUST query only conversations related to the current user and MUST avoid reading global chat lists for client-side filtering.
- **FR-028**: Product view counts and performance telemetry MUST avoid high-frequency writes to single hot documents and MUST remain non-blocking when analytics writes fail.
- **FR-029**: The project MUST document expected read/write cost per major flow, including home, product detail, chat inbox, checkout, notifications, and admin dashboards.
- **FR-030**: Release readiness MUST include Firebase plan assumptions, daily active user estimate, concurrent user estimate, Hosting transfer estimate, and known scaling risks.
- **FR-031**: The project MUST define a staged 100k scale roadmap with gates for 10k, 25k, 50k, and 100k concurrent active users.
- **FR-032**: High-traffic product discovery MUST support cached, precomputed, paginated, or denormalized read models so 100k users do not all attach to the same expensive live catalog queries.
- **FR-033**: Hot counters, product views, analytics events, notifications, and traffic metrics MUST use distributed counters, queues, sampling, or aggregation instead of single-document high-frequency writes.
- **FR-034**: Search and filtering MUST have a dedicated production strategy for large catalogs, such as a managed search index or backend-generated query views.
- **FR-035**: Static assets and product media MUST have a CDN/cache strategy, optimized sizes, immutable asset names where possible, and documented transfer budgets.
- **FR-036**: Production readiness MUST include monitoring dashboards, budget alerts, error-rate thresholds, latency thresholds, rollback steps, and traffic ramp-up rules.
- **FR-037**: The app MUST NOT claim 100k production readiness until staged load tests and Firebase/hosting usage metrics validate the target under realistic buyer, seller, chat, and checkout traffic.

### Key Entities *(include if feature involves data)*

- **Product**: Marketplace listing owned by a seller, including pricing, inventory, images, category, status, variants, and rating summary.
- **CartItem**: Buyer-owned pending purchase item, including product reference, selected variant, quantity, seller, and price snapshot.
- **Order**: Purchase record containing buyer, seller items, address, payment summary, totals, and lifecycle status.
- **SellerProfile**: Store-facing seller data including store name, verification status, policies, and seller rating.
- **MerchantVerification**: Business onboarding data for merchants, including tax ID, business address, verification status, and the approval gate that enables delivery eligibility.
- **Review**: Buyer feedback tied to a product, seller, buyer, and optionally an order.
- **Address**: Buyer-owned delivery destination used during checkout.
- **Report**: Moderation item submitted by users for products, sellers, posts, reviews, or chats.
- **CapacityBudget**: Launch-readiness estimate describing expected users, reads, writes, transfer, quota plan, and risk thresholds for each primary app flow.
- **TelemetryEvent**: Non-critical performance or analytics event that must never block UI completion and must be safe under traffic growth.
- **ScaleStage**: A production-readiness gate for a specific concurrency target, including traffic profile, pass/fail metrics, cost estimate, and rollback criteria.
- **ReadModel**: Precomputed or denormalized data shape optimized for high-volume product discovery, search, recommendations, and home sections.
- **LoadTestRun**: Evidence record for a staged traffic test, including user count, duration, latency, error rate, read/write volume, bandwidth, and cost.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A buyer can complete product discovery to order creation in 5 minutes or less during manual QA.
- **SC-002**: Cart total calculations are covered by automated tests for normal, sale-price, quantity, and out-of-stock cases.
- **SC-003**: Order creation prevents duplicate active orders from repeated checkout submission.
- **SC-004**: Product grids load initial content with skeleton or loading states and avoid unbounded reads.
- **SC-005**: Buyer, seller, and admin order/moderation access rules are verified by tests or documented emulator checks.
- **SC-006**: English and Arabic screens remain readable without overlapping text in the primary shopping flow.
- **SC-007**: `flutter analyze`, `flutter test`, and `flutter build web` pass after QA fixes.
- **SC-008**: Direct product and chat URLs no longer crash when `state.extra` is missing.
- **SC-009**: Static scan finds no empty `onPressed`, `onTap`, or `onLongPress` handlers in production `lib/` UI code unless explicitly documented as disabled.
- **SC-010**: Targeted smoke tests cover cart-to-checkout, product detail, chat detail, profile/settings actions, and at least one Arabic/RTL render path.
- **SC-011**: Updated buyer screens pass `flutter analyze`, `flutter test`, and `flutter build web`.
- **SC-012**: Buyer UI smoke tests verify modern product card labels and checkout blocked/ready messaging.
- **SC-013**: Capacity notes document estimated reads and writes for home, product detail, chat inbox, checkout, notifications, and admin dashboards.
- **SC-014**: Chat inbox reads are limited to the signed-in user's conversations and no longer depend on filtering the latest global chat documents on the client.
- **SC-015**: Product view and screen performance tracking do not perform a write to the same product or telemetry path for every single high-traffic screen open.
- **SC-016**: Firestore query review confirms primary buyer browsing uses explicit limits, documented indexes, and no unbounded production list reads.
- **SC-017**: `flutter analyze`, `flutter test`, and `flutter build web` pass after capacity-readiness changes.
- **SC-018**: A 100k scale roadmap documents architecture, expected bottlenecks, cost controls, and staged gates for 10k, 25k, 50k, and 100k concurrent active users.
- **SC-019**: Load-test criteria define maximum acceptable app error rate, p95 user-visible latency, Firestore read/write growth, Hosting transfer, and estimated cost at every scale stage.
- **SC-020**: High-traffic counters and analytics have a documented distributed or aggregated path before any 25k+ traffic test.
- **SC-021**: Product discovery and search have a documented cache/search/read-model architecture before any 50k+ traffic test.
- **SC-022**: The 100k claim is considered blocked until a staged load test reaches 100k with acceptable latency, error rate, and cost.

## Assumptions

- Existing Flutter, Riverpod, GoRouter, Firebase Auth, Firestore, Storage, FCM, and localization foundations will be reused.
- The app should become marketplace-rich like large ecommerce apps, but must not copy Amazon branding, logos, visual identity, or protected wording.
- PayPal can remain the first payment integration until a final production payment provider is chosen.
- Firestore remains the primary database for the next implementation phase.
- Complex search engines, ad bidding, subscription programs, and warehouse logistics are out of scope for the first release.
- Capacity estimates are planning guidance until validated with real Firebase usage metrics or a staged load test.
- Firebase Spark/free plan is treated as demo/testing capacity only; production launch assumes a paid plan with budget alerts and monitoring.
- The 100k target assumes paid infrastructure, staged rollout, backend aggregation, CDN/cache discipline, and real load-testing budget.
