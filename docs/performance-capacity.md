# Performance and Capacity Notes

Last updated: 2026-05-16

## Current Capacity Estimate

These numbers are planning estimates, not a substitute for Firebase usage metrics or staged load testing.

- Firebase Spark/free plan: safe for demo traffic only. Expect roughly 200-500 concurrent light users for short bursts, but daily Firestore and Hosting quotas can be exhausted quickly.
- Firebase Blaze/paid plan after Phase 47 optimizations: target 2,000 concurrent active users for normal browsing, chat, and checkout traffic.
- Stretch target after staged load testing and monitoring: 5,000 concurrent active users.
- Production target after load test, image optimization, search/index review, and analytics aggregation: 10,000+ concurrent users.
- Strategic target requested by the product owner: 100,000 concurrent active users. This is a roadmap target, not a current readiness claim.

## Firebase Quota Assumptions

- Cloud Firestore free quota includes 50,000 document reads/day, 20,000 writes/day, 20,000 deletes/day, 1 GiB stored data, and 10 GiB/month outbound transfer.
- Firebase Hosting includes no-cost Hosting storage and transfer allowances, but Flutter web first loads can consume transfer quickly when CanvasKit assets are downloaded.
- Firebase Authentication is not the primary capacity bottleneck for regular email/password marketplace traffic, but account creation, SMS, and email actions have abuse and quota limits.
- Production launch should use Blaze billing with budget alerts, usage monitoring, and staged traffic ramp-up.

## Flow Cost Budget

| Flow | Expected read/write shape | Capacity note |
|------|---------------------------|---------------|
| Home, no filter | One capped products listener, category listener, optional user state | Capped at 80 product docs per initial products listener |
| Home, category/subcategory filter | Bounded field-specific product listeners for category id, subcategory id, and legacy category names | Avoids relying on the latest global 80 products for filtered browsing |
| Discovery rails | Reuses the base products provider and local composition | Does not create separate product queries for deals/top-rated/sponsored rails |
| Product detail | One product read when opened by direct URL, related/review/question reads as visible | View tracking should use scattered analytics events, not product document increments |
| Chat inbox | One participant-scoped listener ordered by update time | Must not read global chat lists and filter on the client |
| Checkout | Local cart plus user address/order writes | Keep order creation idempotent and avoid repeated submit writes |
| Notifications | User-scoped notification query/listener | Add limit/order for high-volume users if notification count grows |
| Admin dashboards | Higher read cost, intended for small admin population | Avoid leaving admin dashboards open during peak buyer traffic |

## Phase 47 Changes

- Chat inbox now queries `participants arrayContains currentUserId` before ordering by `updatedAt`.
- Filtered product browsing uses bounded server-side field queries for category and subcategory identifiers, then merges duplicates client-side.
- Product detail no longer increments `products/{productId}.viewCount` on every open, avoiding hot writes to popular product documents.
- Screen performance telemetry is sampled in production so every screen open does not become a Firestore write.
- Firestore indexes document the new participant chat query and product category/subcategory filtered queries.

## 100k Concurrent User Roadmap

The 100k goal requires a staged architecture program. Cloud Firestore can scale real-time systems beyond thousands of operations per second and hundreds of thousands of concurrent users, but the app must avoid hot documents, ramp traffic gradually, and keep bootstrap queries efficient.

### Stage Gates

| Stage | Target | Required proof before moving forward |
|-------|--------|--------------------------------------|
| Stage 1 | 10k concurrent active users | Current Phase 47 optimizations, deployed indexes, usage dashboards, budget alerts, and a one-hour load test with acceptable read/write growth |
| Stage 2 | 25k concurrent active users | Sharded counters or aggregation for product views/favorites/analytics, notification batching, and admin analytics limits |
| Stage 3 | 50k concurrent active users | Dedicated search or precomputed query views for large catalog browsing, cached home/category read models, image optimization, and CDN transfer budget |
| Stage 4 | 100k concurrent active users | Multi-hour staged load test, rollback plan, alert thresholds, cost estimate, hot-path profiling, and evidence that p95 user-visible latency and error rate stay within target |

### Architecture Work Needed

- Product discovery should move from client-composed live listeners to precomputed read models for home, category, sponsored, deals, and recommendation sections.
- Search should move to a dedicated search/index strategy when catalog size or query complexity grows beyond Firestore's economical query shape.
- Product views, favorites, seller metrics, and other high-volume counters should use distributed counters, queued aggregation, or sampled analytics.
- Notifications and analytics should be batched or processed through backend jobs instead of writing one client event for every small interaction at high traffic.
- Product images should be resized into thumbnails, cached with long-lived immutable URLs, and delivered through CDN-friendly paths.
- Flutter web assets should be cache-controlled carefully and monitored for transfer cost after each release.
- Traffic should ramp gradually instead of jumping directly to 100k, following the 500/50/5 style warm-up pattern for Firestore-backed workloads.

### Load-Test Targets

- Traffic mix: 70% browse home/category/search, 15% product detail, 8% chat, 5% cart/checkout, 2% seller/admin.
- Gate duration: minimum 60 minutes for 10k and 25k, minimum 3 hours for 50k and 100k.
- Error rate target: under 1% user-visible failures during each stage.
- Latency target: p95 user-visible screen readiness under 2.5 seconds for cached browse paths and under 4 seconds for checkout/chat paths.
- Cost target: estimated daily cost must be reviewed before each stage and must not exceed the approved budget.
- Rollback trigger: sustained error rate over 2%, p95 latency over target for 10 minutes, quota/budget alert breach, or Firestore hotspot/contention warnings.

## Remaining Risks

- Capacity estimates should be validated with Firebase console usage metrics and a staged load test.
- Search and recommendations still depend on capped Firestore queries and local ranking. A dedicated search service may be needed for very large catalogs.
- Product visitor counts shown in the UI may lag or require a backend aggregation job if real-time public counters are required.
- Admin analytics methods that read large collections should be protected behind limits, aggregation, or backend reports before heavy operations use.
- The app is not 100k-ready until Stage 4 load testing passes with acceptable cost, latency, and error rate.

## Launch Checklist

- Confirm Firebase project is on Blaze before public launch.
- Set budget alerts and Firestore usage alerts.
- Deploy Firestore indexes before releasing the optimized chat/product queries.
- Review Firestore Usage dashboard after test traffic and compare actual reads per user against this document.
- Build and approve the Phase 48 architecture before claiming 100k readiness.
- Run `flutter analyze`, `flutter test`, and `flutter build web` before deployment.

## References

- Firestore real-time scaling guidance: https://firebase.google.com/docs/firestore/real-time_queries_at_scale
- Firestore reads/writes at scale and traffic ramp-up: https://firebase.google.com/docs/firestore/understand-reads-writes-scale
- Firestore distributed counters: https://firebase.google.com/docs/firestore/solutions/counters
- Firebase Hosting cache behavior: https://firebase.google.com/docs/hosting/manage-cache
