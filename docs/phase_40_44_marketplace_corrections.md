# Phase 40-44 Marketplace Corrections

## Phase 40: Product Visitors, Maps & City Search

- Product detail opens increment `products/{productId}.viewCount`.
- Product cards and detail screens show visitor counts.
- Product share menu can copy a Google Maps city link without a Maps API key.
- Advanced search supports city-only filtering and saved search city metadata.

## Phase 41: Seller-Paid Promotions & Deals

- Sellers create promotion orders from seller tools.
- Package pricing: 1 day = 50 EGP, 2 days = 90 EGP, 3 days = 120 EGP, 7 days = 180 EGP, 14 days = 300 EGP.
- Firestore stores requests in `promotion_orders` as `pending_payment`.
- Admins no longer create promotions or discounts directly; they only confirm payment and activate/end seller-created orders.

## Phase 42: Notifications & Chat Deletion

- Welcome-back notifications are limited to one per user per calendar day.
- Firestore tracks `lastWelcomeBackDate` and `dailySignInCount`.
- Conversation deletion is self-only through `hiddenFor`, so the other participant keeps their inbox record.

## Phase 43: Feed Comments & Post Chat

- Comment taps open a full comments screen.
- "View more comments" opens the full comments screen instead of showing a placeholder.
- Users can join a chat tied to a specific post.

## Phase 44: Arabic Coverage

- New copy added in these phases must be included in Arabic QA for product, search, seller, admin, feed, and chat screens.
- Admin promotion wording must stay payment-confirmation based, not admin-created-deal based.
