# Implementation Plan: Amazon-Style Marketplace Experience

**Branch**: `001-amazon-style-marketplace` | **Date**: 2026-05-11 | **Spec**: [spec.md](./spec.md)  
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
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── firestore-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── router/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── admin/
    ├── analytics/
    ├── auth/
    ├── cart/
    ├── chat/
    ├── home/
    ├── notifications/
    ├── orders/          # new
    ├── payments/
    ├── products/
    ├── profile/
    ├── ratings/
    ├── search/
    ├── seller/          # new
    └── shell/

test/
├── widget_test.dart
└── features/
    ├── cart/
    ├── orders/
    └── search/

functions/
└── optional server-side order/payment helpers
```

**Structure Decision**: Use the existing Flutter feature-first architecture. Add new `orders` and `seller` features with the same data/domain/presentation layering already used by products, payments, notifications, ratings, and search.

## Phase 0: Research

Research output is captured in [research.md](./research.md). Main decisions:

- Keep Firestore as the immediate backend.
- Create a first-class `orders` feature.
- Keep payment abstraction separate from order state.
- Use capped Firestore queries and client-side composition for home sections.
- Add seller center as a dedicated feature rather than mixing seller workflows into product screens.

## Phase 1: Design

Design output is captured in:

- [data-model.md](./data-model.md)
- [contracts/firestore-contract.md](./contracts/firestore-contract.md)
- [quickstart.md](./quickstart.md)

## Phase 2: Task Planning

Tasks are captured in [tasks.md](./tasks.md). Implementation should proceed in buyer-value slices:

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

