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

