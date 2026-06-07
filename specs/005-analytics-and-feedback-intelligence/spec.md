# Spec: Analytics and Feedback Intelligence

**Status**: Planned  
**Parent roadmap**: `specs/003-enterprise-roadmap/`  
**Entry gate**: Phase 0 and Phase 1 gates must pass; raw analytics privacy contract must be approved.

## Goal

Create privacy-safe event, session, funnel, and feedback intelligence before AI or advanced dashboards depend on behavior data.

## Scope

- Client event tracking service.
- Session ID generation and session lifecycle.
- Funnel tracking for home, product view, cart, checkout, payment, and order success.
- Feedback capture for bugs, payment issues, UI problems, seller complaints, and feature requests.
- Backend aggregation jobs for admin dashboard summaries.

## Out Of Scope

- AI recommendations.
- Raw private chat analytics.
- Payment credential storage.

## Exit Gate

- Admin analytics displays event-derived summaries.
- Raw event access is restricted.
- Sensitive events have retention and metadata allowlists.
