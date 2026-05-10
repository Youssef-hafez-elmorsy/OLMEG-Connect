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

