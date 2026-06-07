# Phase 24-39 Enterprise Readiness

This document records the app-side contracts created for the remaining marketplace phases. External systems such as payment webhooks, Cloud Functions, AI providers, app-store approvals, courier APIs, CI/CD, and production Firebase rule deployment still require real provider configuration, but the Flutter/Firebase contracts are now defined.

## Phase 24: Loyalty, Coupons, Wallet, Membership

- `coupon_validations`: coupon validation requests with anti-abuse checks.
- `loyalty_ledger`: points for purchases, reviews, referrals, and seller milestones.
- `wallets`: loyalty points and store credit balance document per user.
- Referral and membership fields are ready through wallet and coupon validation metadata.

## Phase 25: Notifications And Automation

- `notification_preferences`: order, chat, promotion, moderation, and seller alert settings.
- `automation_queue`: unpaid orders, abandoned carts, unread messages, email templates, retry attempts, quiet hours, and language-aware jobs.
- Admin broadcasts remain tied to existing admin notification segmentation.

## Phase 26: Fraud And Marketplace Safety

- `risk_signals`: duplicate accounts, suspicious listings, spam reports, payment anomalies, device/session metadata, and rate-limit evidence.
- `{targetType}_risk`: explainable score summaries for users, sellers, products, orders, and reports.
- Risk dashboard can read these collections alongside admin audit logs.

## Phase 27: AI Assistant Layer

- `ai_tasks`: buyer assistant, seller assistant, moderation summaries, FAQ drafts, translation, review analysis, and fraud analysis.
- Guardrails are stored on every task: brand imitation, unsafe advice, misleading claims, and privacy.
- Provider is pluggable so OpenAI, Gemini, Rekognition, Vision, or another provider can be connected through Cloud Functions.

## Phase 28: Social Commerce

- `creator_attributions`: product tags in posts, creator storefronts, curated collections, affiliate/referral attribution, and privacy-safe social proof.
- Existing report/moderation queues cover live/chat abuse and product misrepresentation until streaming APIs are connected.

## Phase 29: Finance And Payouts

- `finance_ledger`: GMV, platform fee, tax, shipping, seller payout, payout lifecycle, and reconciliation hooks.
- Finance access should use finance-specific admin roles before production.

## Phase 30: Localization And Regions

- Existing English/Arabic localization is extended by the release checklist.
- Currency, phone, address, tax, delivery, legal text, category names, and search synonyms are identified as configurable regional data.

## Phase 31: Enterprise Admin Console

- Admin operations, reports, moderation, promotions, support, audit logs, and permission-aware routing are active.
- CSV exports and large table filters should use server-side query/export jobs for production scale.

## Phase 32: Analytics And Experimentation

- `experiment_events`: A/B exposure tracking.
- `analytics_events`, `performance_events`, and `app_errors` cover funnel, retention, quality, crash, and alerting inputs.
- Privacy-safe event taxonomy is documented in `docs/release_readiness.md`.

## Phase 33: Backend And Infrastructure

- Critical server work should be moved to Cloud Functions: payment webhooks, totals validation, stock validation, coupons, payouts, moderation, reminders, aggregation, cleanup, and fraud jobs.
- `infrastructure_readiness` records implementation status for CI/CD, backups, cost monitoring, queues, and search/reporting migration.

## Phase 34: Security

- Existing audit logs, role-aware admin routing, merchant delivery rules, upload metadata, and risk signals support a strict security posture.
- Final production rule hardening must be deployed in Firebase rules and tested with emulators before store submission.

## Phase 36: AI, Moderation, Fraud, Recommendation

- AI task contracts support moderation, recommendations, natural-language search, translation, review analysis, and assistant flows.
- Provider evaluation is documented as pluggable instead of hardcoding one vendor without credentials.

## Phase 37: Technical Infrastructure

- App-side monitoring, error reporting, image cache headers, local cache, queue contracts, release gates, and staging flags are in place.
- CI/CD and CDN-backed thumbnail generation remain external infrastructure tasks.

## Phase 38: Future Expansion

- Delivery tracking, escrow, expanded merchant verification, product video, live shopping, saved alerts, and AI ranking have data-contract entry points.
- Courier, escrow, OCR, video processing, and streaming providers need production accounts.

## Phase 39: Final Launch

- Web deployment is live at `https://olmeg-connect.web.app/`.
- Admin route is `https://olmeg-connect.web.app/#/admin`.
- Final Google Play/App Store readiness still requires store assets, signing, disclosures, real-device QA, production security review, and payment webhook verification.
