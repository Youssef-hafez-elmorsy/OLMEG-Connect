# Research: Olmeg Connect Enterprise Roadmap

## Decision: Use a program-level Spec Kit feature

**Rationale**: The roadmap is broader than a single implementation slice. A dedicated Spec Kit feature gives the team one canonical planning artifact while allowing future phases to become separate implementation specs.

**Alternatives considered**:

- Keep only `docs/master-enterprise-roadmap-tasks.md`: rejected because it does not integrate with Spec Kit gates or task format.
- Merge into `specs/002-admin-web-console`: rejected because the roadmap covers payments, analytics, fulfillment, AI, seller tools, and scaling beyond admin.

## Decision: Phase 0 and Phase 1 block major expansion

**Rationale**: Current audit showed admin compile failures, failing admin tests, broad Firestore fallback risk, and direct write concerns. New enterprise features should not be built on unstable or unsafe foundations.

**Alternatives considered**:

- Start Paymob immediately: rejected because payment correctness depends on backend-only writes, audit integrity, and passing build/test gates.
- Start AI immediately: rejected because AI requires trustworthy event, moderation, and security foundations.

## Decision: Paymob only for first production payment phase

**Rationale**: One provider reduces scope, improves testability, and lets the team complete webhook verification, reconciliation, refunds, and admin operations before adding provider abstraction.

**Alternatives considered**:

- Paymob plus PayPal: rejected as too broad for the first production payment phase.
- Build generic multi-provider payment layer first: rejected because it delays the first verified production flow.

## Decision: Split later phases into future Spec Kit features

**Rationale**: Fulfillment, notifications, AI moderation, AI intelligence, seller ecosystem, and scaling are large enough to need their own specs, plans, and tasks after foundation gates pass.

**Alternatives considered**:

- Put all implementation details in one huge tasks file: rejected because it would be difficult to execute, test, and review safely.

## Decision: Analytics must be privacy-first and aggregate-first

**Rationale**: Marketplace analytics will include sensitive behavior such as checkout attempts, failed payments, reports, support issues, and moderation signals. Raw event access should be limited, and admin dashboards should rely on aggregated summaries whenever possible.

**Constraints**:

- Do not store payment credentials, card data, secrets, raw private chat bodies, or merchant verification documents in analytics metadata.
- Use append-only raw events with limited retention.
- Use backend aggregation jobs for dashboards, funnels, and AI inputs.
- Treat checkout, payment, report, support, and moderation events as sensitive.

**Alternatives considered**:

- Let admin pages query raw analytics events directly: rejected because it expands privacy and access-control risk.
- Add AI recommendations before analytics contracts: rejected because recommendations need trustworthy event semantics and retention rules.
