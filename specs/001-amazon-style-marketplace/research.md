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

