# Data Model: Enterprise Roadmap

## EnterprisePhase

Represents one major roadmap stage.

Fields:

- `id`: Stable phase identifier, such as `phase-0`.
- `name`: Human-readable phase name.
- `priority`: Critical, Very High, High, or Medium.
- `goal`: Outcome the phase must deliver.
- `dependsOn`: Earlier phase IDs that must pass before this phase starts.
- `exitGateIds`: Phase gates that prove completion.

## PhaseGate

Represents a measurable checkpoint.

Fields:

- `id`: Stable gate identifier.
- `phaseId`: Owning phase.
- `description`: What must be true.
- `evidence`: Required proof, such as command output, test result, deployed URL, or checklist.
- `blocking`: Whether the gate blocks later phases.

## RoadmapTask

Represents an executable task.

Fields:

- `id`: Spec Kit task ID.
- `phaseId`: Owning phase.
- `story`: Related user story, if applicable.
- `description`: Action to perform.
- `targetPath`: File, document, config, rules file, or test target.
- `parallelizable`: Whether it can run in parallel with other tasks.
- `status`: Planned, in progress, complete, blocked, or deferred.

## PaymentProviderScope

Defines allowed payment provider scope.

Fields:

- `currentProvider`: Paymob.
- `outOfScopeProviders`: PayPal, Stripe, Apple Pay, Google Pay.
- `entryGate`: Phase 0 and Phase 1 must pass.
- `exitGate`: Verified Paymob webhook and reconciliation flow.

## SecurityBoundary

Defines where trust is enforced.

Fields:

- `boundaryType`: Firestore Rules, Storage Rules, Cloud Function, Custom Claim, audit log, or CI gate.
- `protectedAction`: Action or data category being protected.
- `requiredEvidence`: Rule test, callable function test, audit record, or build check.

## AdminOperation

Represents a marketplace operations workflow.

Fields:

- `route`: Admin route.
- `roles`: Allowed roles.
- `dataSource`: Collection or backend source.
- `actions`: Allowed commands.
- `auditRequired`: Whether each mutation requires audit evidence.
- `paginationRequired`: Whether server-side pagination is required.

## AnalyticsEvent

Represents behavior captured for analytics.

Fields:

- `name`: Event name.
- `actorType`: User, seller, admin, system.
- `journeyStep`: Screen or funnel step.
- `privacyLevel`: Public, internal, sensitive, or restricted.
- `aggregationTarget`: Dashboard or report that consumes the event.
- `eventId`: Client-generated UUID for idempotency.
- `userId`: Authenticated user ID, or null only for anonymous pre-login events if explicitly allowed by a later analytics spec.
- `sessionId`: Client session UUID rotated on app restart or timeout.
- `occurredAt`: Client event time.
- `receivedAt`: Backend server time.
- `platform`: android, ios, web, or admin_web.
- `metadata`: Small allowlisted map; must not contain payment card data, secrets, raw chat bodies, or merchant identity documents.

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

Privacy constraints:

- Store raw events with least privilege and limited retention.
- Publish admin dashboards from aggregated summaries, not unrestricted raw event reads.
- Treat checkout, payment, report, and support events as sensitive.

## PaymobPayment

Represents one Paymob-backed payment attempt.

Fields:

- `paymentId`: Internal payment document ID.
- `orderId`: Related order ID.
- `userId`: Buyer ID.
- `provider`: Always `paymob` in the current scope.
- `paymobIntentionId`: Paymob intention/session identifier.
- `amountCents`: Integer amount in minor currency units.
- `currency`: Payment currency.
- `state`: `pending`, `processing`, `paid`, `failed`, `refunded`, or `disputed`.
- `createdAt`: Backend server timestamp.
- `updatedAt`: Backend server timestamp.
- `lastWebhookId`: Last processed Paymob webhook ID/hash.
- `reconciliationId`: Optional reconciliation document ID.
- `failureReason`: Optional normalized failure reason.

State rules:

- Clients may read their own payment records but cannot create, update, or delete payment records.
- Order payment state changes must be written by backend verification after Paymob confirmation.
- Duplicate webhook delivery must be idempotent.

## DomainEvent

Represents backend business activity.

Fields:

- `name`: Event name.
- `source`: Originating workflow.
- `payloadSummary`: Required business data.
- `consumers`: Notifications, analytics, admin dashboard, AI risk, or fulfillment.
- `auditRequired`: Whether immutable audit evidence is required.
