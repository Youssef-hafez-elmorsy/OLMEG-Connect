# Phase Gate Checklist: Enterprise Roadmap

**Purpose**: Validate that phases do not start before their prerequisites pass  
**Created**: 2026-05-18  
**Feature**: [spec.md](../spec.md)

## Phase 0 Gate

- [X] Admin compile error fixed.
- [X] Root `flutter analyze` passes.
- [X] Admin `flutter analyze` passes.
- [X] Admin `flutter test` passes.
- [X] Admin `flutter build web` passes.
- [X] Selected security and admin separation tests pass.

## Phase 1 Gate

- [X] Broad Firestore fallback removed or denied by default.
- [X] Explicit chat rules added.
- [X] User PII reads tightened.
- [X] Sensitive admin actions require backend functions.
- [X] Sensitive audit logs are backend-only.
- [X] Storage rules protect merchant documents.
- [X] Rule tests cover direct client write denial.

## Phase 2 Gate

- [ ] Legacy public-app admin code removed or quarantined.
- [ ] Admin tables support real pagination.
- [ ] Admin pages support server-side filters.
- [ ] Detail pages exist for core operations.
- [ ] Audit history is visible where needed.
- [X] Release checklist exists and is used.

## Phase 3 Gate

- [X] Analytics event schema exists.
- [ ] Session tracking exists.
- [ ] Funnel tracking exists.
- [ ] Feedback system exists.
- [ ] Admin analytics summaries are event-derived.

## Phase 4 Paymob Gate

- [X] Paymob backend initiation exists.
- [X] Paymob webhook verification exists.
- [X] Orders cannot be marked paid by client writes.
- [X] Payment states are implemented.
- [X] Reconciliation records exist.
- [X] Admin payment operations page exists.
- [ ] Paymob tests pass.

## Later Phase Gate

- [X] Fulfillment starts only after Paymob order/payment state is stable.
- [X] Notifications start only after event and queue foundations are stable.
- [X] AI starts only after analytics, security, and moderation data are trustworthy.
- [X] Seller ecosystem starts only after analytics and fulfillment foundations exist.
- [X] Scaling starts with monitoring and load-test evidence.
