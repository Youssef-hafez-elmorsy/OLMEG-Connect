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

