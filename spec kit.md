# Spec Kit: Amazon-Style Marketplace Experience

**Project**: Olmeg Connect  
**Feature**: `001-amazon-style-marketplace`  
**Created**: 2026-05-11  
**Source folder**: `specs/001-amazon-style-marketplace/`

This file combines the Spec Kit documents for the Amazon-style marketplace plan into one readable master document.

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
3. **Given** a product detail page, **When** the buyer views it, **Then** they see images, price, variants, stock state, seller info, ratings, delivery estimate, return policy, and related products.
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
- **FR-003**: Product details MUST show image gallery, title, description, price, sale price, stock state, variants, seller information, rating summary, reviews, delivery estimate, return policy, and related products.
- **FR-004**: Buyers MUST be able to add products to cart, update quantities, remove products, save products for later, and favorite products.
- **FR-005**: Checkout MUST support address selection, delivery option selection, payment method selection, order summary, and final order confirmation.
- **FR-006**: Orders MUST support statuses for pending payment, paid, preparing, shipped, delivered, cancelled, and refunded.
- **FR-007**: Buyers MUST be able to view order history and order details.
- **FR-008**: Sellers MUST be able to manage listings, inventory, order fulfillment status, and buyer conversations.
- **FR-009**: Admins MUST be able to moderate products, users, sellers, reviews, reported content, and promotional placements.
- **FR-010**: Notifications MUST cover order updates, chat messages, price changes, moderation actions, and promotions.
- **FR-011**: Reviews MUST support product-level and seller-level feedback, with verified-purchase status when available.
- **FR-012**: User-facing commerce flows MUST support English and Arabic localization.
- **FR-013**: Analytics MUST record search, product view, add to cart, checkout started, order placed, favorite, review submitted, and seller actions.
- **FR-014**: Firestore security rules MUST restrict user-owned data, seller-owned inventory, admin-only moderation, and private order access.

### Key Entities *(include if feature involves data)*

- **Product**: Marketplace listing owned by a seller, including pricing, inventory, images, category, status, variants, and rating summary.
- **CartItem**: Buyer-owned pending purchase item, including product reference, selected variant, quantity, seller, and price snapshot.
- **Order**: Purchase record containing buyer, seller items, address, payment summary, totals, and lifecycle status.
- **SellerProfile**: Store-facing seller data including store name, verification status, policies, and seller rating.
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

- [ ] Audit current product entity/model/datasource fields.
- [ ] Add or normalize `salePrice`, `stockQuantity`, `variants`, `status`, `sellerId`, `ratingAverage`, and `ratingCount`.
- [ ] Update product cards to show sale pricing, stock state, ratings, and seller trust hints.
- [ ] Update product detail page with delivery info, return policy, variants, and related product placeholder.
- [ ] Add address entity/model/provider.
- [ ] Add address book screens for list, create, edit, delete, and default address.
- [ ] Validate cart item stock and variant availability.
- [ ] Add checkout review screen with subtotal, shipping, discount, tax placeholder, and total.
- [ ] Add cart total unit tests.

## Phase 2: Orders & Payments

- [ ] Create `lib/features/orders/` with data/domain/presentation folders.
- [ ] Add `OrderEntity`, `OrderItemEntity`, and order status enum.
- [ ] Add Firestore order datasource.
- [ ] Add order repository and provider.
- [ ] Add order creation from checkout.
- [ ] Add order list screen for buyers.
- [ ] Add order detail screen with status timeline.
- [ ] Connect payment success/failure to order status.
- [ ] Add notification event for order updates.
- [ ] Add Firestore rules for buyer/seller/admin order access.
- [ ] Add order creation and status transition tests.

## Phase 3: Seller Center

- [ ] Create `lib/features/seller/`.
- [ ] Add seller dashboard route.
- [ ] Add seller inventory screen.
- [ ] Add seller order queue screen.
- [ ] Add seller profile/storefront screen.
- [ ] Add seller policy fields for returns and shipping.
- [ ] Add seller rating summary.
- [ ] Restrict seller screens to authenticated seller/admin users.

## Phase 4: Discovery & Personalization

- [ ] Redesign home as commerce-first sections.
- [ ] Add category rail/grid.
- [ ] Add deals section.
- [ ] Add top-rated section.
- [ ] Add recently viewed persistence.
- [ ] Add related products query on product detail.
- [ ] Improve advanced search sorting.
- [ ] Add analytics events for impressions, product view, add to cart, checkout started, and order placed.

## Phase 5: Trust, Reviews & Moderation

- [ ] Tie product reviews to completed orders where available.
- [ ] Add verified purchase marker.
- [ ] Add review images.
- [ ] Add review moderation status.
- [ ] Add report action for product, seller, review, and post.
- [ ] Expand admin moderation queues.
- [ ] Add admin actions for suspend seller, reject product, hide review, and resolve report.

## Phase 6: Production Readiness

- [ ] Add Firestore indexes for product search, product category, seller products, buyer orders, seller orders, and moderation queues.
- [ ] Harden Firestore rules for products, cart, orders, reviews, seller profiles, and admin actions.
- [ ] Add skeleton and empty states to major commerce screens.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Complete manual QA for buyer, seller, admin, English, and Arabic flows.

