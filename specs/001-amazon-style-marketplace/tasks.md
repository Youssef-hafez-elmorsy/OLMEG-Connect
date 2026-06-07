# Tasks: Amazon-Style Marketplace Experience

**Spec**: `specs/001-amazon-style-marketplace/spec.md`
**Plan**: `specs/001-amazon-style-marketplace/plan.md`

## Phase 1: Commerce Foundation

- [x] Audit current product entity/model/datasource fields.
- [x] Add or normalize `salePrice`, `stockQuantity`, `variants`, `status`, `sellerId`, `ratingAverage`, and `ratingCount`.
- [x] Update product cards to show sale pricing, stock state, ratings, and seller trust hints.
- [x] Update product detail page with approved-merchant-only delivery guidance, seller-contact guidance for non-merchant products, return policy, variants, and related product placeholder.
- [x] Add address entity/model/provider.
- [x] Add address book screens for list, create, edit, delete, and default address.
- [x] Validate cart item stock and variant availability.
- [x] Show add-to-cart and checkout actions only for approved merchant products; direct regular-user and unverified-seller products to seller contact.
- [x] Add checkout review screen with subtotal, approved-merchant-only delivery guidance, seller-contact guidance for non-merchant products, discount, tax placeholder, and total.
- [x] Add cart total unit tests.

## Phase 2: Orders & Payments

- [x] Create `lib/features/orders/` with data/domain/presentation folders.
- [x] Add `OrderEntity`, `OrderItemEntity`, and order status enum.
- [x] Add Firestore order datasource.
- [x] Add order repository and provider.
- [x] Add order creation from checkout.
- [x] Add order list screen for buyers.
- [x] Add order detail screen with status timeline.
- [x] Connect payment success/failure to order status.
- [x] Add notification event for order updates.
- [x] Add Firestore rules for buyer/seller/admin order access.
- [x] Add order creation and status transition tests.

## Phase 3: Seller Center

- [x] Create `lib/features/seller/`.
- [x] Add seller dashboard route.
- [x] Add seller inventory screen.
- [x] Add seller order queue screen.
- [x] Add seller profile/storefront screen.
- [x] Add seller policy fields for returns and shipping.
- [x] Add seller rating summary.
- [x] Restrict seller screens to authenticated seller/admin users.

## Phase 4: Discovery & Personalization

- [x] Redesign home as commerce-first sections.
- [x] Add category rail/grid.
- [x] Add deals section.
- [x] Add top-rated section.
- [x] Add recently viewed persistence.
- [x] Add related products query on product detail.
- [x] Improve advanced search sorting.
- [x] Add analytics events for impressions, product view, add to cart, checkout started, and order placed.

## Phase 5: Trust, Reviews & Moderation

- [x] Tie product reviews to completed orders where available.
- [x] Add verified purchase marker.
- [x] Add review images.
- [x] Add review moderation status.
- [x] Add report action for product, seller, review, and post.
- [x] Expand admin moderation queues.
- [x] Add admin actions for suspend seller, reject product, hide review, and resolve report.

## Phase 6: Production Readiness

- [x] Add Firestore indexes for product search, product category, seller products, buyer orders, seller orders, and moderation queues.
- [x] Harden Firestore rules for products, cart, orders, reviews, seller profiles, and admin actions.
- [x] Add skeleton and empty states to major commerce screens.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Complete manual QA for buyer, seller, admin, English, and Arabic flows.

## Phase 7: Merchant Onboarding & Delivery Eligibility

- [x] Add account type selection during registration: regular user or merchant.
- [x] Add merchant registration fields for tax ID, business address, legal business name, business phone, and verification documents where required.
- [x] Add `MerchantVerification` model/entity and persistence.
- [x] Add merchant verification status: draft, submitted, approved, rejected, suspended.
- [x] Restrict product delivery features to approved merchant accounts only.
- [x] Keep add-to-cart/checkout hidden for regular-user, unverified, rejected, or suspended merchant products; route buyers to seller contact instead.
- [x] Add admin review queue for merchant verification.
- [x] Add Firestore rules for merchant verification privacy and admin-only approval.
- [x] Add tests for registration account type, merchant validation, and delivery eligibility.

## Phase 8: Post Screen UI/UX Upgrade

- [x] Redesign post feed header and composer for faster posting.
- [x] Add post feed summary stats and clearer filter controls.
- [x] Add polished loading, empty, and error states.
- [x] Improve post card visual hierarchy and action ergonomics.
- [x] Verify post screen with analyzer/tests.

## Phase 9: Chat Screen UI/UX Upgrade

- [x] Redesign chat list with search, role context, and improved unread/empty states.
- [x] Upgrade chat detail header with product and participant context.
- [x] Improve message bubbles, timestamps, input bar, and quick actions.
- [x] Add polished loading, empty, and error states.
- [x] Verify chat screens with analyzer/tests.

## Phase 10: Full App UX QA & Accessibility Polish

- [x] Run manual QA for buyer, seller, admin, English, and Arabic flows.
- [x] Review all primary screens for mobile overflow, text clipping, and RTL layout issues.
- [x] Add accessibility labels and semantic hints to icon-only actions.
- [x] Normalize empty, loading, error, and success states across marketplace, posts, chat, seller, and admin screens.
- [x] Review color contrast and tap target sizes across light/dark modes.
- [x] Capture screenshots for key flows and document UX issues to fix.

## Phase 11: Production Checkout, Payment Recovery & Receipts

- [x] Replace placeholder payment flow with a production-ready payment confirmation path.
- [x] Add payment recovery for succeeded payment but interrupted order confirmation.
- [x] Add buyer receipt screen and seller order invoice summary.
- [x] Add order cancellation and refund request flows.
- [x] Add idempotency safeguards for repeated place-order taps and payment callbacks.
- [x] Add payment emulator/manual QA checklist.

## Phase 12: Delivery, Fulfillment & Buyer Tracking

- [x] Add delivery method selection only for products sold by approved merchants.
- [x] Add seller fulfillment actions for preparing, shipped, delivered, cancelled, and refunded states.
- [x] Add buyer-facing tracking timeline with estimated delivery and seller notes.
- [x] Add delivery address snapshot review on order detail.
- [x] Add notification triggers for each fulfillment transition.
- [x] Add tests for allowed and blocked order status transitions.

## Phase 13: Seller Growth, Promotions & Store Quality

- [x] Add seller storefront public page with products, policies, ratings, and contact action.
- [x] Add seller listing quality checklist before publishing.
- [x] Add promoted product placement controls for admins.
- [x] Add deals/campaign management for seller discounts.
- [x] Add seller analytics for views, conversion, orders, and repeat buyers.
- [x] Add product draft and scheduled publish support.

## Phase 14: Advanced Search, Recommendations & Personalization

- [x] Add server-backed search indexes or Algolia-style integration when Firestore filtering is not enough.
- [x] Add saved searches and buyer alerts for matching products.
- [x] Add personalized recommendation sections based on views, favorites, cart, and orders.
- [x] Add better category taxonomy and synonym support for English/Arabic search.
- [x] Add search result ranking for availability, seller quality, rating, and freshness.
- [x] Add analytics validation for impressions and recommendation clicks.

## Phase 15: Admin Operations, Support & Auditability

- [x] Add admin support dashboard for orders, payments, reports, sellers, and users.
- [x] Add audit log entries for admin actions and seller fulfillment changes.
- [x] Add dispute workflow for buyer/seller order problems.
- [x] Add moderation history per product, seller, review, post, and report.
- [x] Add bulk moderation actions and admin notes.
- [x] Add role-based admin permissions beyond a single admin flag.

## Phase 16: Offline, Performance & Data Efficiency

- [x] Add pagination to product, post, order, review, report, and chat lists.
- [x] Add local cache strategy for recently viewed, categories, and stable seller/profile data.
- [x] Optimize image loading, thumbnails, and upload compression.
- [x] Add performance measurements for home, product detail, checkout, chat, and feed screens.
- [x] Reduce Firestore reads for home sections and notification counts.
- [x] Add low-network and retry UX for checkout, chat, image upload, and order updates.

## Phase 17: Release Readiness, Monitoring & Store Launch

- [x] Add crash reporting and production analytics dashboards.
- [x] Add environment separation for development, staging, and production Firebase projects.
- [x] Add release build checklist for Android, iOS, and web.
- [x] Add privacy policy and terms review for payments, merchant data, reports, and analytics.
- [x] Add backup/restore and data retention plan for Firestore and Storage.
- [x] Complete final launch QA with real devices and Arabic/English screenshots.

## Phase 18: Amazon-Style Product Detail Depth

- [x] Add multi-section product detail layout with highlights, specifications, seller box, Q&A, reviews, related products, and comparison blocks.
- [x] Add product specification tables per category.
- [x] Add buyer Q&A with seller/admin answers and moderation.
- [x] Add product comparison for similar listings.
- [x] Add image/video gallery with zoom, thumbnails, and seller-uploaded media validation.
- [x] Add "frequently bought together" and bundle suggestion sections.
- [x] Add product trust panel with return window, seller verification, delivery eligibility, and report action.

## Phase 19: Cart, Wishlist, Save Later & Collections

- [x] Add persistent cloud cart synced across devices.
- [x] Add save-for-later persistence instead of local-only state.
- [x] Add wishlist/favorites collections with privacy controls.
- [x] Add shareable lists for gift, project, or event shopping.
- [x] Add price-drop and back-in-stock alerts for saved products.
- [x] Add cart conflict resolution when price, stock, or seller status changes.
- [x] Add cart recommendations, substitutes, and bundle prompts.

## Phase 20: Shipping Network, Delivery Pricing & Address Intelligence

- [x] Add shipping zones, city coverage, and approved merchant delivery radius.
- [x] Add delivery fee calculation by address, approved merchant, weight, and delivery method.
- [x] Add address validation and normalized city/region fields.
- [x] Add estimated delivery dates per product and per order.
- [x] Add split-shipment support when cart contains products from multiple sellers.
- [x] Add delivery instructions and phone confirmation fields.
- [x] Add seller pickup option with meeting location guidance for non-delivery products.

## Phase 21: Returns, Refunds, Disputes & Buyer Protection

- [x] Add return request flow with reason, photos, and timeline.
- [x] Add seller approval/rejection workflow for returns.
- [x] Add admin dispute escalation with evidence review.
- [x] Add refund status tracking connected to payment state.
- [x] Add buyer protection policy screens and order-level eligibility.
- [x] Add seller performance penalties for unresolved disputes.
- [x] Add automated notifications for return/refund lifecycle.

## Phase 22: Seller Professional Tools & Bulk Operations

- [x] Add seller bulk product upload via CSV or spreadsheet template.
- [x] Add bulk price, stock, category, status, and discount editing.
- [x] Add seller product drafts, duplicate listing, and listing templates.
- [x] Add inventory low-stock alerts and restock reminders.
- [x] Add seller vacation mode and handling-time settings.
- [x] Add seller payout dashboard with order earnings and fees.
- [x] Add seller performance dashboard for cancellation rate, fulfillment speed, reviews, and response time.

## Phase 23: Ads, Sponsored Products & Campaign Manager

- [x] Add sponsored product placement model and Firestore contract.
- [x] Add admin campaign approval and budget controls.
- [x] Add seller campaign creation with daily budget and targeting.
- [x] Add ad impression, click, conversion, and spend analytics.
- [x] Add sponsored labels and ranking rules in discovery/search.
- [x] Add guardrails to prevent low-quality or suspended products from promotion.
- [x] Add campaign billing readiness hooks.

## Phase 24: Loyalty, Coupons, Wallet & Membership

- [x] Add coupon model for seller coupons, admin coupons, and category campaigns.
- [x] Add coupon validation in cart and checkout.
- [x] Add loyalty points for purchases, reviews, referrals, and seller milestones.
- [x] Add wallet balance or store credit model for refunds and promotions.
- [x] Add membership tier concept with benefits such as free delivery or early deals.
- [x] Add referral codes and invite tracking.
- [x] Add anti-abuse rules for coupon stacking and self-referrals.

## Phase 25: Notifications, Email, Push & Messaging Automation

- [x] Add notification preference center for order, chat, promotions, moderation, and seller alerts.
- [x] Add push notification deep links to products, orders, chats, reports, and admin queues.
- [x] Add email templates for receipts, merchant verification, order updates, returns, and disputes.
- [x] Add scheduled reminders for unpaid orders, abandoned carts, and unread seller messages.
- [x] Add notification delivery status and retry tracking.
- [x] Add quiet hours and language-aware notification text.
- [x] Add admin broadcast segmentation by role, location, and activity.

## Phase 26: Fraud Detection, Risk Scoring & Marketplace Safety

- [x] Add fraud signal collection for duplicate accounts, suspicious listings, spam reports, and payment anomalies.
- [x] Add risk score fields for users, sellers, products, orders, and reports.
- [x] Add automated hold/review state for risky orders or sellers.
- [x] Add blocked keywords, prohibited product categories, and image review hooks.
- [x] Add rate limits for posting, messaging, reporting, reviewing, and checkout attempts.
- [x] Add device/session audit metadata where privacy policy permits.
- [x] Add admin risk dashboard with explainable reasons and override actions.

## Phase 27: AI Shopping Assistant & Seller Assistant

- [x] Add buyer assistant for product discovery, comparison, and purchase guidance.
- [x] Add seller assistant for listing title, description, category, price, and policy suggestions.
- [x] Add AI-generated product FAQ drafts from description and chat history where allowed.
- [x] Add moderation assistant for report summarization and duplicate report grouping.
- [x] Add Arabic/English assistant responses with commerce-safe disclaimers.
- [x] Add guardrails to avoid protected brand imitation, unsafe advice, or misleading claims.
- [x] Add AI feedback tracking for accepted/rejected suggestions.

## Phase 28: Social Commerce, Live Selling & Creator Tools

- [x] Add product tagging inside posts and creator recommendations.
- [x] Add seller live session model for showcasing products.
- [x] Add live comments, pinned products, and post-live replay metadata.
- [x] Add creator storefronts and curated collections.
- [x] Add affiliate/referral attribution for creator-driven sales.
- [x] Add social proof blocks: trending products, community picks, and recent purchases where privacy-safe.
- [x] Add moderation tools for live/chat abuse and product misrepresentation.

## Phase 29: Multi-Vendor Marketplace Finance & Accounting

- [x] Add platform fee, seller commission, tax, shipping, discount, and payout breakdowns.
- [x] Add seller payout lifecycle: pending, available, paid, failed, held.
- [x] Add monthly seller statements and downloadable summaries.
- [x] Add admin financial dashboard for GMV, revenue, refunds, disputes, and payouts.
- [x] Add tax/VAT configuration by merchant and region.
- [x] Add reconciliation reports between orders, payments, refunds, and payouts.
- [x] Add finance access controls separate from general admin tools.

## Phase 30: Multi-Language, Multi-Currency & Regional Expansion

- [x] Add full localization coverage audit for English and Arabic strings.
- [x] Add currency abstraction beyond EGP with exchange-rate-ready formatting.
- [x] Add regional catalog rules for product availability and delivery eligibility.
- [x] Add locale-aware category names, attributes, and search synonyms.
- [x] Add RTL QA automation or screenshot checks for critical screens.
- [x] Add country/region configuration for phone, address, tax, and delivery formats.
- [x] Add legal content variants by region.

## Phase 31: Web Admin Console & Operations Portal

- [x] Add responsive admin console layout optimized for desktop web.
- [x] Add product, order, seller, user, report, review, ad, and finance tables with filters.
- [x] Add detail drawers for fast admin review without losing table context.
- [x] Add bulk operations for moderation, seller status, campaign approval, and report resolution.
- [x] Add export tools for CSV reports.
- [x] Add admin activity timeline and internal notes.
- [x] Add permission-based navigation for support, moderation, finance, and super admin roles.

## Phase 32: Observability, Experimentation & Growth Analytics

- [x] Add funnel dashboards for search, product view, add to cart, checkout, payment, and reorder.
- [x] Add A/B test framework for home sections, ranking, checkout copy, and seller prompts.
- [x] Add retention cohorts for buyers and sellers.
- [x] Add product quality metrics such as conversion, return rate, report rate, and review score.
- [x] Add alerting for payment failures, Firestore cost spikes, crash spikes, and notification failures.
- [x] Add privacy-safe event taxonomy documentation.
- [x] Add data deletion/export workflows for privacy compliance.

## Phase 33: Scale Architecture & Backend Hardening

- [x] Move critical checkout, order status, payment, payout, and moderation transitions to Cloud Functions.
- [x] Add server-side validation for totals, stock, seller status, coupon eligibility, and duplicate orders.
- [x] Add background jobs for reminders, analytics aggregation, seller scores, and cleanup.
- [x] Add emulator-based integration tests for Firestore rules and Cloud Functions.
- [x] Add backup/restore drills and disaster recovery runbook.
- [x] Add cost monitoring and query budget controls.
- [x] Evaluate migration points for dedicated search, SQL reporting, or event warehouse.

## Phase 34: Enterprise Security Upgrade

- [x] Replace any development-friendly Firestore access with strict user, seller, admin, support, moderator, and super-admin permissions.
- [x] Limit regular users to approved products, own profile, own chats, own orders, and reviews for purchased products.
- [x] Limit sellers to their own products, inventory, seller dashboard, and seller-owned order items.
- [x] Limit admins to reports, moderation, merchant verification, analytics, and notification management according to role.
- [x] Harden Firebase Storage rules for product images, avatars, review images, and merchant documents.
- [x] Restrict uploaded file types to safe image/document types and block executable/script/archive uploads.
- [x] Enforce upload limits such as product image count, image size, avatar size, and user-folder isolation.
- [x] Add anti-spam rate limits for messages, product posts, reviews, searches, account creation, and reports.
- [x] Add spam detection for repeated messages, fake reviews, bot behavior, rapid account creation, and suspicious listings.
- [x] Add privacy-reviewed device/session tracking for banned-user evasion and suspicious login detection.
- [x] Add secure authentication upgrades: email verification, OTP/MFA support, session expiration, token refresh validation, and failed-login monitoring.
- [x] Add chat safety controls for scam links, fake payment links, harassment, phone-number abuse, and toxic language.
- [x] Add payment security with backend verification, webhooks, duplicate transaction detection, refund validation, and fake-client-response prevention.
- [x] Add enterprise RBAC roles: user, seller, merchant, moderator, support, admin, and super_admin.
- [x] Add audit logs for product deletions, admin actions, merchant approvals, user bans, refunds, payment changes, and security violations.

## Phase 35: Enterprise Admin Dashboard

- [x] Build a professional web admin dashboard, preferably with Flutter Web, for marketplace operations.
- [x] Add analytics dashboard for active users, daily sales, revenue, product statistics, growth, conversion, and marketplace activity.
- [x] Add charts for daily revenue, weekly sales, monthly growth, retention, and seller performance.
- [x] Add product moderation center for pending products, AI-flagged products, suspicious listings, and product reports.
- [x] Add admin product actions: approve, reject, soft delete, shadow ban, and escalate.
- [x] Add user management system for bans, seller suspension, chat mute, posting restrictions, merchant verification, and user report review.
- [x] Add AI moderation center showing scam probability, spam probability, toxicity score, fake listing score, and counterfeit probability.
- [x] Add live monitoring dashboard for live users, live chats, live orders, active sellers, fraud alerts, and server health.
- [x] Add notification management for push campaigns, user segmentation, promotional messages, and seller announcements.
- [x] Add notification targeting for categories, handmade buyers, inactive users, and new users.
- [x] Add support and ticket system for refund requests, delivery disputes, seller complaints, and live support chat.

## Phase 36: Real AI Integration

- [x] Replace rule-only product moderation with AI-assisted moderation for product titles, descriptions, images, pricing, and categories.
- [x] Detect counterfeit products, weapons, drugs, fraud, scam listings, and unsafe content using AI moderation services.
- [x] Evaluate AI services such as OpenAI Moderation API, Google Gemini, AWS Rekognition, and Google Vision API.
- [x] Add AI recommendation engine using behavior, product views, search history, purchases, favorites, and chat activity.
- [x] Upgrade search from keyword matching to natural-language intent search.
- [x] Support natural queries such as "cheap gaming laptop with strong battery" and map them to filters/ranking.
- [x] Add AI fraud detection for fake accounts, spam sellers, suspicious payments, fake reviews, and scam activity.
- [x] Add in-app AI marketplace assistant for product discovery, recommendations, seller help, policy explanation, and checkout guidance.
- [x] Add AI translation for Arabic and English product descriptions, chat messages, reviews, and support content.
- [x] Add AI review analysis for sentiment, spam detection, fake review detection, and seller quality signals.

## Phase 37: Scalability & Infrastructure Upgrade

- [x] Expand Cloud Functions for payment webhooks, notification automation, AI moderation processing, analytics aggregation, cleanup jobs, and fraud jobs.
- [x] Add CDN/image optimization with global image caching, thumbnails, faster product loading, and reduced bandwidth usage.
- [x] Add caching strategy using local device caching, Firestore query caching, and Redis or equivalent server cache if backend expands.
- [x] Add queue system for notifications, AI processing, emails, background jobs, and retryable tasks.
- [x] Add Firebase Crashlytics, Performance Monitoring, error tracking, and server health monitoring.
- [x] Add CI/CD pipeline for automatic tests, builds, staging deployments, and production deployments.
- [x] Add production staging environment and release gates before store submission.

## Phase 38: Enterprise Marketplace Feature Expansion

- [x] Add delivery tracking system for approved merchant orders with shipping APIs, courier integration, delivery status tracking, and estimated delivery dates.
- [x] Add escrow payment system to hold payment until buyer confirms delivery or dispute window closes.
- [x] Expand merchant verification with ID upload, business verification, tax documents, OCR verification, and AI identity validation.
- [x] Add video products with product video uploads, marketplace reels, and product preview clips.
- [x] Add live streaming marketplace features inspired by live shopping platforms.
- [x] Add saved searches with price alerts, restock alerts, and product match notifications.
- [x] Add advanced recommendation engine for personalized homepage, trending products, AI ranking, and behavioral recommendations.

## Phase 39: Production Launch Preparation

- [x] Prepare Google Play release with production security rules, privacy policy, terms of service, app signing, and Play Store assets.
- [x] Prepare App Store release with Apple compliance, iOS optimization, privacy disclosures, and app review readiness.
- [x] Finalize production infrastructure with monitoring, backup systems, database optimization, server scaling, and disaster recovery.
- [x] Complete payment provider production setup and verify webhook behavior in staging.
- [x] Complete final security review for Firestore, Storage, Cloud Functions, admin roles, and API keys.
- [x] Complete final AI, moderation, fraud, support, and analytics readiness review.
- [x] Complete final release QA across Android, iOS, web, English, Arabic, buyer, seller, admin, and support flows.

## Phase 40: Product Visitor Counts, Location Sharing & City Search

- [x] Add product visitor counts to product data, product cards, and product detail screens.
- [x] Increment product visitor counts when a product detail screen is opened.
- [x] Add Google Maps location sharing without a paid Maps API by using public maps search links.
- [x] Add a product share action for copying the product city Google Maps link.
- [x] Add advanced search filtering by city only, with saved search alert support.
- [x] Store city search context in search analytics/impression keys.

## Phase 41: Seller-Paid Promotions & Deals

- [x] Remove admin-created direct promotion/deal actions from the admin promotion screen.
- [x] Add seller-created paid promotion packages: 1 day = 50 EGP, 2 days = 90 EGP, 3 days = 120 EGP, 7 days = 180 EGP, 14 days = 300 EGP.
- [x] Store promotion and deal requests in Firestore as `promotion_orders` with `pending_payment` status.
- [x] Prevent discounts/deals from activating until payment is confirmed.
- [x] Allow admin only to mark a seller-created promotion order as paid and activate/end it.
- [x] Sync paid promotion order state with sponsored campaign records.

## Phase 42: Welcome-Back Notification Limits & Chat Deletion

- [x] Track daily sign-in counts per user in Firestore.
- [x] Send welcome-back notification no more than one time per user per day.
- [x] Store `lastWelcomeBackDate` and `dailySignInCount` to avoid repeated notifications across multiple same-day sign-ins.
- [x] Add self-only chat conversation deletion using `hiddenFor` instead of deleting the shared conversation.
- [x] Keep conversations available to the other participant when one user deletes it from their inbox.

## Phase 43: Feed Comment Screen & Post Chat Join

- [x] Replace broken "view more comments" behavior with a full post comments screen.
- [x] Route comment button taps to the dedicated comments screen.
- [x] Support reading all comments and adding new comments from the comments screen.
- [x] Add a post chat join action that opens or creates a chat tied to the specific post.
- [x] Prevent users from joining a chat with themselves on their own post.

## Phase 44: Arabic Coverage & Marketplace Copy Corrections

- [x] Add the new promotion, visitor, city, chat, and comment flows to the localization coverage checklist.
- [x] Confirm new user-facing flows use simple marketplace language that can be translated cleanly to Arabic.
- [x] Keep Arabic translation review as a release-blocking QA item for product, feed, chat, seller, and admin screens.
- [x] Document that admin promotion wording must describe payment confirmation, not admin-created deals.

## Phase 45: Full App QA Stabilization & Runtime Error Cleanup

- [x] T045-001 [US4] Replace forced `state.extra` casts in `lib/core/router/app_router.dart` for product and chat routes with safe loading/not-found recovery paths.
- [x] T045-002 [US4] Add direct-link route tests for product and chat detail behavior without navigation extras in `test/features/qa/stabilization_test.dart`.
- [x] T045-003 [US4] Replace empty settings/profile action handlers with real navigation, clear unavailable messages, or hidden disabled actions in `lib/features/profile/presentation/screens/settings_screen.dart` and `lib/features/profile/presentation/screens/profile_screen.dart`.
- [x] T045-004 [US4] Replace empty chat detail action handlers with implemented options or clear unavailable messages in `lib/features/chat/presentation/screens/chat_detail_screen.dart`.
- [x] T045-005 [US4] Remove or quarantine stale demo-only chat UI from production scans in `lib/features/chat/presentation/screens/chat_detail_screen_new.dart`.
- [x] T045-006 [US4] Tighten checkout/payment copy and disabled-state explanations in `lib/features/cart/presentation/screens/checkout_review_screen.dart` and related order/payment screens.
- [x] T045-007 [US4] Add widget smoke tests for cart-to-checkout, profile/settings actions, route safety, and Arabic/RTL rendering under `test/features/qa/stabilization_test.dart`.
- [x] T045-008 [US4] Run and document `flutter analyze`, `flutter test`, `flutter build web`, and static empty-handler scan before marking the QA phase complete.

## Phase 46: Modern Buyer UI/UX Refresh

- [x] T046-001 [US5] Create reusable buyer experience UI primitives for hero panels, trust chips, and responsive content rails in `lib/core/widgets/buyer_experience_widgets.dart`.
- [x] T046-002 [US5] Upgrade home marketplace hero, search actions, section headers, and responsive product rails in `lib/features/home/presentation/screens/home_screen.dart`.
- [x] T046-003 [US5] Upgrade product card visual hierarchy, delivery/trust badges, sale price treatment, and tap targets in `lib/features/products/presentation/widgets/product_card.dart` and `lib/core/widgets/product_card.dart`.
- [x] T046-004 [US5] Refine product detail trust, delivery/contact, related product, and bottom action presentation in `lib/features/products/presentation/screens/product_detail_screen.dart`.
- [x] T046-005 [US5] Refresh cart and checkout summary hierarchy, blocked-state explanations, and next-step calls to action in `lib/features/products/presentation/screens/cart_screen.dart` and `lib/features/cart/presentation/screens/checkout_review_screen.dart`.
- [x] T046-006 [US5] Add buyer UI smoke tests for updated product card and checkout UX in `test/features/qa/buyer_ui_refresh_test.dart`.
- [x] T046-007 [US5] Run `flutter analyze`, `flutter test`, `flutter build web`, and update this phase completion state.

## Phase 47: Performance & Capacity Readiness

- [x] T047-001 [US6] Document current Firebase capacity assumptions, free-plan limits, paid-plan assumptions, and per-flow read/write estimates in `docs/performance-capacity.md`.
- [x] T047-002 [US6] Optimize chat inbox queries to read only conversations involving the signed-in user in `lib/features/chat/data/datasources/chat_remote_datasource.dart` and update required Firestore indexes in `firestore.indexes.json`.
- [x] T047-003 [US6] Review product discovery and category filtering for server-side limits/indexes in `lib/features/products/data/datasources/product_remote_datasource.dart`, `lib/features/products/presentation/providers/product_discovery_provider.dart`, and `lib/features/home/presentation/screens/home_screen.dart`.
- [x] T047-004 [US6] Replace per-open product view writes with a safe low-contention tracking strategy in `lib/features/products/presentation/screens/product_detail_screen.dart` and any supporting analytics service.
- [x] T047-005 [US6] Make screen performance telemetry production-safe through sampling, environment gating, or aggregation in `lib/core/widgets/screen_performance_probe.dart`.
- [x] T047-006 [US6] Add or update tests for chat query behavior, product discovery limits, and telemetry safety under `test/features/qa/`.
- [x] T047-007 [US6] Run `flutter analyze`, `flutter test`, `flutter build web`, and update this phase completion state after approval and implementation.

## Phase 48: 100k Concurrent User Scale Roadmap

- [ ] T048-001 [US7] Expand `docs/performance-capacity.md` with a 100k architecture roadmap covering 10k, 25k, 50k, and 100k staged gates.
- [ ] T048-002 [US7] Design high-volume product discovery read models for home, category, deals, sponsored, and recommendation surfaces in `docs/performance-capacity.md`.
- [ ] T048-003 [US7] Design sharded/distributed counters and aggregation paths for product views, favorites, analytics, notifications, and seller metrics in `docs/performance-capacity.md`.
- [ ] T048-004 [US7] Design a large-catalog search strategy and migration trigger for dedicated search or backend-generated query views in `docs/performance-capacity.md`.
- [ ] T048-005 [US7] Define CDN, Flutter web asset, product image, and cache-control budgets for 100k traffic in `docs/performance-capacity.md` and `firebase.json`.
- [ ] T048-006 [US7] Add load-test scenarios, target traffic mix, pass/fail thresholds, cost guardrails, and rollback criteria in `docs/performance-capacity.md`.
- [ ] T048-007 [US7] Add tests or static guards for any implemented 100k-critical query, counter, cache, or telemetry changes under `test/features/qa/`.
- [ ] T048-008 [US7] Run `flutter analyze`, `flutter test`, `flutter build web`, and deploy only after the 100k architecture changes are approved and implemented.
