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

