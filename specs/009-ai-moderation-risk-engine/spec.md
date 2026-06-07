# Spec: AI Moderation and Risk Engine

**Status**: Planned  
**Entry gate**: Security, analytics, and moderation data contracts must be stable.

## Goal

Add risk-based moderation that assists staff without bypassing human/admin control for high-risk actions.

## Scope

- Risk score model.
- Risk signal extraction for text, suspicious pricing, seller history, reports, links, phone numbers, duplicate listings, and image risk signals.
- AI moderation service boundary.
- Review queues for medium/high risk content.
- Admin evidence view with reasons and highlighted signals.

## Exit Gate

- Low-risk content can be auto-processed where policy allows.
- Medium/high-risk content enters review.
- AI decisions are explainable, logged, and reversible by authorized staff.
