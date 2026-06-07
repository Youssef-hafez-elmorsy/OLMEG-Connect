# Spec Kit: Amazon-Style Marketplace Experience

**Project**: Olmeg Connect  
**Feature**: `001-amazon-style-marketplace`  
**Created**: 2026-05-11  
**Source folder**: `specs/001-amazon-style-marketplace/`

This file combines the Spec Kit documents for the Amazon-style marketplace plan into one readable master document.

---

# Latest Discussion Update

**Updated**: 2026-05-11

## What Was Updated

- Created and consolidated the Spec Kit direction for making Olmeg Connect a richer ecommerce marketplace experience.
- Captured the major product direction: discovery, product details, cart, checkout, orders, seller tools, reviews, moderation, analytics, and English/Arabic commerce support.
- Confirmed the implementation should reuse the current Flutter feature-first architecture, Riverpod state management, GoRouter routing, Firebase services, and existing marketplace/social modules.
- Added a reusable app brand component in the app code for consistent logo/title/tagline presentation on auth screens.
- Updated the app tagline to `Everything you need in one place` with Arabic localization.
- Updated the login and registration screens to use the shared brand lockup.
- Prepared the external graduation document by moving the filled Olmeg Connect project content into the EELU template and keeping a backup.
- Completed Spec Kit Phase 2 by adding the first-class `orders` feature, checkout order creation, buyer order history/detail screens, payment-to-order status mapping, order notifications, Firestore order rules, and order tests.
- Completed the remaining implementation phases through automated verification: seller center, discovery/personalization, trust/reviews/reports/moderation, Firestore indexes, hardened rules, clean analyzer, and passing tests.
- Added and completed Phase 8 and Phase 9 for post screen and chat screen UI/UX upgrades, with clean analyzer and passing tests.

## What We Will Update Next

1. Seller center: seller dashboard, inventory, seller order queue, storefront/profile, return/shipping policies, seller ratings, and seller/admin access rules.
2. Discovery and personalization: commerce-first home, categories, deals, top-rated products, recently viewed products, related products, search sorting, and analytics.
3. Trust and moderation: verified purchase reviews, review images, review moderation, report actions, admin moderation queues, and admin enforcement actions.
4. Production readiness: Firestore indexes, hardened Firestore/Storage rules, loading/empty states, `flutter analyze`, `flutter test`, and manual QA for buyer, seller, admin, English, and Arabic flows.

---

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

### Edge Cases

- Product price, stock, or status changes after an item is added to cart.
- Buyer taps place order more than once because of network delay.
- Payment succeeds but client loses network before order confirmation is displayed.
- Seller attempts to update an order that belongs to another seller.
- Buyer attempts to review a product without a completed order.
- Arabic locale requires right-to-left layout and localized commerce labels.
- Firestore query requires a missing composite index.

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

### Key Entities *(include if feature involves data)*

- **Product**: Marketplace listing owned by a seller, including pricing, inventory, images, category, status, variants, and rating summary.
- **CartItem**: Buyer-owned pending purchase item, including product reference, selected variant, quantity, seller, and price snapshot.
- **Order**: Purchase record containing buyer, seller items, address, payment summary, totals, and lifecycle status.
- **SellerProfile**: Store-facing seller data including store name, verification status, policies, and seller rating.
- **MerchantVerification**: Business onboarding data for merchants, including tax ID, business address, verification status, and the approval gate that enables delivery eligibility.
- **Review**: Buyer feedback tied to a product, seller, buyer, and optionally an order.
- **Address**: Buyer-owned delivery destination used during checkout.
- **Report**: Moderation item submitted by users for products, sellers, posts, reviews, or chats.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A buyer can complete product discovery to order creation in 5 minutes or less during manual QA.
- **SC-002**: Cart total calculations are covered by automated tests for normal, sale-price, quantity, and out-of-stock cases.
- **SC-003**: Order creation prevents duplicate active orders from repeated checkout submission.
- **SC-004**: Product grids load initial content with skeleton or loading states and avoid unbounded reads.
- **SC-005**: Buyer, seller, and admin order/moderation access rules are verified by tests or documented emulator checks.
- **SC-006**: English and Arabic screens remain readable without overlapping text in the primary shopping flow.

## Assumptions

- Existing Flutter, Riverpod, GoRouter, Firebase Auth, Firestore, Storage, FCM, and localization foundations will be reused.
- The app should become marketplace-rich like large ecommerce apps, but must not copy Amazon branding, logos, visual identity, or protected wording.
- PayPal can remain the first payment integration until a final production payment provider is chosen.
- Firestore remains the primary database for the next implementation phase.
- Complex search engines, ad bidding, subscription programs, and warehouse logistics are out of scope for the first release.

---

# Implementation Plan: Amazon-Style Marketplace Experience

**Branch**: `001-amazon-style-marketplace` | **Date**: 2026-05-11 | **Spec**: `specs/001-amazon-style-marketplace/spec.md`  
**Input**: Feature specification from `/specs/001-amazon-style-marketplace/spec.md`

## Summary

Evolve Olmeg Connect into a richer ecommerce marketplace: stronger product discovery, product detail trust signals, cart validation, checkout, orders, seller tools, moderation, reviews, analytics, and English/Arabic commerce support. The implementation will reuse the existing Flutter feature architecture, Riverpod state management, GoRouter routes, Firebase services, and current marketplace/social modules.

## Technical Context

**Language/Version**: Dart SDK `>=3.0.0 <4.0.0`, Flutter project  
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Firebase Core/Auth/Firestore/Storage/Messaging, cached_network_image, image_picker, intl, flutter_paypal, flutter_rating_bar  
**Storage**: Cloud Firestore for app data, Firebase Storage for images, SharedPreferences for lightweight local settings/recently viewed  
**Testing**: `flutter_test`, targeted unit/widget tests, Firebase emulator checks documented where automated rules tests are not yet available  
**Target Platform**: Android, iOS, Web, desktop Flutter targets already present  
**Project Type**: Cross-platform mobile/web marketplace app  
**Performance Goals**: Initial product sections load progressively; product grids use pagination or capped queries; cached images avoid repeated downloads  
**Constraints**: Avoid unbounded Firestore reads, prevent duplicate checkout submission, preserve English/Arabic UX, do not copy Amazon branding  
**Scale/Scope**: Existing multi-feature marketplace app with products, cart, search, payments, chat, posts, notifications, ratings, admin, analytics, and profile modules

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Codebase fit**: PASS. The plan keeps the existing feature-first structure under `lib/features/**`.
- **Testing standard**: PASS with follow-up. Core cart/order logic must get automated tests before implementation is considered complete.
- **User experience consistency**: PASS. The plan reuses shared widgets and requires English/Arabic commerce screens.
- **Security and privacy**: PASS with follow-up. Firestore rules and access tests are explicit deliverables for orders, seller data, and moderation.
- **Performance**: PASS with follow-up. Product discovery must use capped queries, caching, and loading states.

## Project Structure

### Documentation (this feature)

```text
specs/001-amazon-style-marketplace/
|- spec.md
|- plan.md
|- research.md
|- data-model.md
|- quickstart.md
|- contracts/
|  `- firestore-contract.md
`- tasks.md
```

### Source Code (repository root)

```text
lib/
|- core/
|  |- router/
|  |- services/
|  |- theme/
|  |- utils/
|  `- widgets/
`- features/
   |- admin/
   |- analytics/
   |- auth/
   |- cart/
   |- chat/
   |- home/
   |- notifications/
   |- orders/          # new
   |- payments/
   |- products/
   |- profile/
   |- ratings/
   |- search/
   |- seller/          # new
   `- shell/

test/
|- widget_test.dart
`- features/
   |- cart/
   |- orders/
   `- search/

functions/
`- optional server-side order/payment helpers
```

**Structure Decision**: Use the existing Flutter feature-first architecture. Add new `orders` and `seller` features with the same data/domain/presentation layering already used by products, payments, notifications, ratings, and search.

## Phase 0: Research

Research output is captured in `specs/001-amazon-style-marketplace/research.md`. Main decisions:

- Keep Firestore as the immediate backend.
- Create a first-class `orders` feature.
- Keep payment abstraction separate from order state.
- Use capped Firestore queries and client-side composition for home sections.
- Add seller center as a dedicated feature rather than mixing seller workflows into product screens.

## Phase 1: Design

Design output is captured in:

- `specs/001-amazon-style-marketplace/data-model.md`
- `specs/001-amazon-style-marketplace/contracts/firestore-contract.md`
- `specs/001-amazon-style-marketplace/quickstart.md`

## Phase 2: Task Planning

Tasks are captured in `specs/001-amazon-style-marketplace/tasks.md`. Implementation should proceed in buyer-value slices:

1. Product model and commerce UI upgrades.
2. Cart validation and checkout review.
3. Order feature and buyer order history.
4. Seller dashboard and seller order management.
5. Discovery and recommendation sections.
6. Reviews, reports, moderation, rules, indexes, and tests.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| New `orders` feature | Orders are a first-class commerce domain with lifecycle, permissions, and notifications | Placing orders inside cart or payments would mix temporary cart state with permanent purchase records |
| New `seller` feature | Seller workflows need dedicated screens for inventory, fulfillment, and store policy | Adding seller actions to product screens would become hard to navigate and test |
| Payment/order split | Payment state and order lifecycle can diverge during network or provider failures | A single status field would hide failure modes and make recovery harder |

---

# Research: Amazon-Style Marketplace Experience

## Decision: Keep Firebase/Firestore as the Immediate Backend

**Rationale**: The existing app already uses Firebase Auth, Cloud Firestore, Storage, Messaging, and Functions structure. Reusing these avoids a platform rewrite and keeps the first implementation focused on commerce behavior.

**Alternatives considered**:

- Dedicated SQL backend: better for relational reporting, but higher migration cost.
- External search engine immediately: useful later, but not required to ship first buyer/seller order flows.

## Decision: Add a First-Class Orders Feature

**Rationale**: Orders need their own entity, repository, provider, screens, status transitions, notifications, and rules. This should not live inside cart or payments.

**Alternatives considered**:

- Store orders under cart: rejected because cart is mutable pre-purchase state.
- Store orders only under user documents: rejected because sellers and admins need scoped access.

## Decision: Split Payment State From Order Lifecycle

**Rationale**: Payment can fail, succeed late, or require confirmation while the order remains pending. Keeping these concerns separate makes recovery and support easier.

**Alternatives considered**:

- One `status` field for everything: simpler UI, but weak for real payment edge cases.

## Decision: Add Seller Center as Its Own Feature

**Rationale**: Sellers need inventory, order queue, fulfillment status, and store policy screens. A dedicated feature keeps buyer product browsing clean.

**Alternatives considered**:

- Add seller controls into existing product screens: rejected because it blurs buyer and seller mental models.

## Decision: Commerce Home Uses Capped Sections

**Rationale**: Firestore works well for small indexed sections. Home should combine several capped queries such as deals, top-rated, category rows, and recently viewed.

**Alternatives considered**:

- One large personalized feed query: rejected because it risks unbounded reads and weak index behavior.

## Decision: Preserve Existing English/Arabic Localization

**Rationale**: The app already includes English and Arabic localization. All new buyer-facing commerce labels should join that system.

**Alternatives considered**:

- Ship English first: rejected because the app already has bilingual foundations and commerce flows should remain consistent.

---

# Data Model: Amazon-Style Marketplace Experience

## Product

Represents a sellable marketplace listing.

**Fields**:

- `id`: string
- `sellerId`: string
- `title`: localized/display string
- `description`: string
- `categoryId`: string
- `brand`: string optional
- `condition`: enum `new`, `used`, `handmade`, `refurbished`
- `price`: number
- `salePrice`: number optional
- `currency`: string
- `imageUrls`: string list
- `variants`: `ProductVariant` list
- `stockQuantity`: number
- `status`: enum `draft`, `pendingReview`, `active`, `rejected`, `suspended`, `soldOut`
- `ratingAverage`: number
- `ratingCount`: number
- `createdAt`: timestamp
- `updatedAt`: timestamp

## ProductVariant

Represents selectable product options such as color, size, or material.

**Fields**:

- `id`: string
- `label`: string
- `attributes`: map
- `priceDelta`: number optional
- `stockQuantity`: number

## CartItem

Represents a buyer-owned pre-order item.

**Fields**:

- `id`: string
- `userId`: string
- `productId`: string
- `sellerId`: string
- `quantity`: number
- `selectedVariantId`: string optional
- `unitPriceSnapshot`: number
- `currency`: string
- `addedAt`: timestamp
- `updatedAt`: timestamp

## Address

Represents a buyer delivery destination.

**Fields**:

- `id`: string
- `userId`: string
- `fullName`: string
- `phone`: string
- `line1`: string
- `line2`: string optional
- `city`: string
- `region`: string optional
- `postalCode`: string optional
- `country`: string
- `isDefault`: boolean
- `createdAt`: timestamp
- `updatedAt`: timestamp

## Order

Represents a committed buyer purchase.

**Fields**:

- `id`: string
- `buyerId`: string
- `sellerIds`: string list
- `items`: `OrderItem` list
- `shippingAddress`: embedded address snapshot
- `payment`: `PaymentSummary`
- `subtotal`: number
- `shippingFee`: number
- `tax`: number
- `discount`: number
- `total`: number
- `currency`: string
- `status`: enum `pendingPayment`, `paid`, `preparing`, `shipped`, `delivered`, `cancelled`, `refunded`
- `createdAt`: timestamp
- `updatedAt`: timestamp

## OrderItem

Represents a purchased product snapshot inside an order.

**Fields**:

- `productId`: string
- `sellerId`: string
- `titleSnapshot`: string
- `imageUrlSnapshot`: string optional
- `selectedVariantSnapshot`: map optional
- `quantity`: number
- `unitPrice`: number
- `lineTotal`: number
- `fulfillmentStatus`: enum `pending`, `preparing`, `shipped`, `delivered`, `cancelled`, `refunded`

## PaymentSummary

Represents payment state attached to an order.

**Fields**:

- `provider`: string
- `providerPaymentId`: string optional
- `status`: enum `notStarted`, `pending`, `authorized`, `paid`, `failed`, `refunded`
- `paidAt`: timestamp optional
- `failureReason`: string optional

## SellerProfile

Represents store-facing seller information.

**Fields**:

- `userId`: string
- `displayName`: string
- `storeName`: string
- `ratingAverage`: number
- `ratingCount`: number
- `verificationStatus`: enum `unverified`, `pending`, `verified`, `suspended`
- `returnPolicy`: string
- `shippingMethods`: list
- `createdAt`: timestamp
- `updatedAt`: timestamp

## Review

Represents buyer feedback.

**Fields**:

- `id`: string
- `productId`: string
- `sellerId`: string
- `buyerId`: string
- `orderId`: string optional
- `rating`: number
- `title`: string optional
- `body`: string
- `imageUrls`: string list
- `isVerifiedPurchase`: boolean
- `status`: enum `visible`, `pendingModeration`, `hidden`, `removed`
- `createdAt`: timestamp
- `updatedAt`: timestamp

---

# Quickstart: Amazon-Style Marketplace Experience

## Prerequisites

- Flutter SDK available on PATH.
- Firebase project configuration already present.
- Dependencies restored with `flutter pub get`.

## Setup

```powershell
flutter pub get
```

## Analyze

```powershell
flutter analyze
```

## Test

```powershell
flutter test
```

## Manual QA Flow

1. Sign in as a buyer.
2. Open home and verify categories, product sections, loading states, and localized text.
3. Search for a product and apply price, category, condition, rating, and sort filters.
4. Open product detail and verify gallery, price, stock, variants, seller, reviews, delivery, and return information.
5. Add product to cart and update quantity.
6. Start checkout, select address and payment method, review totals, and place order.
7. Open order history and verify status timeline.
8. Sign in as a seller and update inventory/order fulfillment.
9. Sign in as admin and verify moderation queues.
10. Repeat primary buyer flow in Arabic locale.

## Spec Kit Workflow

Use the installed Codex Spec Kit skills from `.agents/skills`:

```text
$speckit-constitution
$speckit-specify
$speckit-plan
$speckit-tasks
$speckit-implement
```

This feature already has the initial spec and plan in `specs/001-amazon-style-marketplace/`.

---

# Firestore Contract: Amazon-Style Marketplace Experience

## Collections

```text
products/{productId}
users/{userId}/cart/{cartItemId}
users/{userId}/addresses/{addressId}
orders/{orderId}
sellerProfiles/{sellerId}
reviews/{reviewId}
reports/{reportId}
```

## Access Rules Intent

### Products

- Public users may read active products.
- Sellers may create products for themselves.
- Sellers may update their own draft, pending, active, or sold-out products except moderation-only fields.
- Admins may update moderation status and featured placement.

### Cart

- Buyers may read and write only their own cart items.
- Cart item writes must reference active products and valid quantities.

### Addresses

- Buyers may read and write only their own addresses.
- Checkout may read the selected buyer address.

### Orders

- Buyers may read their own orders.
- Sellers may read order items that belong to them.
- Sellers may update fulfillment state only for their own order items.
- Admins may read and update moderation/support fields.
- Order creation should validate buyer identity, item snapshots, totals, and stock assumptions.

### Seller Profiles

- Public users may read active seller profiles.
- Sellers may update their own profile policy and display fields.
- Admins may update verification and suspension state.

### Reviews

- Public users may read visible reviews.
- Buyers may create reviews for their completed orders.
- Buyers may edit or remove their own reviews while allowed by policy.
- Admins may hide or remove reviews.

### Reports

- Authenticated users may create reports.
- Report creators may read their own reports.
- Admins may read and resolve all reports.

## Required Index Areas

- Products by `status`, `categoryId`, `createdAt`.
- Products by `status`, `ratingAverage`, `createdAt`.
- Products by `status`, `sellerId`, `createdAt`.
- Products by `status`, `price`, `categoryId`.
- Orders by `buyerId`, `createdAt`.
- Orders by `sellerIds`, `createdAt`.
- Reviews by `productId`, `status`, `createdAt`.
- Reports by `status`, `createdAt`.

---

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
