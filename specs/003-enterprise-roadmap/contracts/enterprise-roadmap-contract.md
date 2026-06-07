# Contract: Enterprise Roadmap Execution

## Phase Contract

Each phase must define:

- Stable phase number.
- Priority.
- Goal.
- Task list.
- Exit gate.
- Dependencies.
- Out-of-scope boundaries.

## Task Contract

Each task in `tasks.md` must follow:

```text
- [ ] T001 [P] [US1] Description with exact file path or artifact target
```

Rules:

- Checkbox is required.
- Task ID is required and sequential.
- `[P]` appears only for parallel-safe tasks.
- User story label appears for user-story phases.
- Exact file path or artifact target is required.

## Payment Scope Contract

Provider in scope:

- Paymob.

Providers out of scope:

- PayPal.
- Stripe.
- Apple Pay.
- Google Pay.
- Multi-provider abstraction.

Phase 4 cannot start until:

- Phase 0 build stabilization passes.
- Phase 1 production security lock passes.

Payment completion requires:

- Backend payment initiation.
- Verified Paymob webhook.
- Backend-only order status update.
- Payment audit log.
- Reconciliation record.
- Admin payment operations visibility.

## Analytics Contract

Analytics work must start with a privacy-safe event contract before dashboards or AI consume behavior data.

Required first events:

- `app_opened`
- `session_started`
- `screen_viewed`
- `product_viewed`
- `search_started`
- `checkout_started`
- `payment_failed`
- `chat_started`
- `post_created`
- `report_submitted`

Rules:

- Raw event writes must be append-only.
- Raw events must not include payment credentials, secrets, raw private chat messages, or merchant verification documents.
- Admin dashboards should read aggregated summary documents, not unrestricted raw event collections.
- Any event used for AI, fraud, or moderation decisions must document retention and review boundaries.

## Paymob Webhook Contract

Paymob is the only payment provider in scope for the current production payment phase.

Webhook requirements:

- Verify Paymob authenticity with the configured HMAC secret before trusting payload state.
- Store raw webhook evidence in a backend-only collection.
- Process duplicate webhook deliveries idempotently.
- Update internal payment and order state only from backend code.
- Create immutable audit/reconciliation evidence for successful, failed, refunded, and disputed states.
- Reject any direct client write that attempts to mark a payment/order as paid.

## Gate Contract

A phase is not complete until every exit gate has evidence.

Valid evidence examples:

- Passing command output.
- Test result.
- Security rule test.
- Build artifact.
- Deployment URL.
- Checklist with completed items.
- Audit log sample.
