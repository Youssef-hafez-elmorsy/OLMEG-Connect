# Spec: Paymob Production Payment Infrastructure

**Status**: Partial implementation exists  
**Parent roadmap**: `specs/003-enterprise-roadmap/`  
**Provider scope**: Paymob only.

## Goal

Use Paymob as the single production payment provider with backend initiation, verified webhook processing, reconciliation records, and admin payment operations visibility.

## Implemented Foundation

- Backend-created Paymob checkout session support in Cloud Functions.
- Paymob webhook receiver with HMAC verification path.
- Backend payment and reconciliation documents.
- Firestore rules block direct client writes to payment records.
- Public Flutter checkout starts Paymob payment flow.
- Admin Web Console has Paymob payment operations route.

## Remaining Work

- End-to-end sandbox success/failure test evidence.
- Duplicate webhook tests.
- Refund and dispute workflows.
- Stronger operational dashboards for failed payments and recovery.
- Production secret rotation and environment validation.

## Exit Gate

- Paymob webhook is the source of truth for payment confirmation.
- Orders cannot become paid from client writes.
- Admins can investigate failed, refunded, and disputed payments.
