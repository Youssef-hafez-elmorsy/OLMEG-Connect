# Design Direction: Premium Marketplace + Admin Security Console

**Chosen directions**: Premium Marketplace for the public app, Admin Security Console for the standalone admin web app.  
**Date**: 2026-05-31  
**Figma status**: Figma plugin handshake is currently unavailable, so this document is the source design brief until Figma can be used to create editable mockups.

## North Star

Olmeg Connect should feel like a trusted commerce product, not a demo marketplace. The public app should help buyers decide quickly with product evidence, seller trust, delivery readiness, Paymob checkout confidence, and polished Arabic/RTL states. The admin web app should feel like a serious operations console where every action has role context, evidence, and audit traceability.

## Public App: Premium Marketplace

### Visual Language

- Keep the existing Olmeg neon green as the brand accent, but use it sparingly for primary actions, trust states, selected filters, and key confirmations.
- Keep dark and light themes through `AppTheme`, `AppThemeHelper`, `AppColors`, `AppSpacing`, and shared widgets.
- Use product imagery as the primary visual signal. Avoid decorative panels that compete with product content.
- Prefer dense but readable marketplace layouts: clear category filters, horizontal discovery rails, responsive grids, trust badges, and sticky purchase actions.
- Arabic/RTL layouts must preserve hierarchy, spacing, and icon direction.

### Screen Plan

1. **Home and Discovery**
   - Upgrade `HomeScreen` into a premium storefront with a compact search-first header, category/subcategory controls, campaign/deals rail, sponsored rail, top-rated rail, and personalized recommendations.
   - Keep `BuyerHeroPanel`, `BuyerSectionHeader`, and `BuyerTrustChip`, but make the hero more commerce-focused and less decorative.
   - Add responsive grid behavior for web/tablet/mobile with stable card dimensions.

2. **Product Cards and Product Detail**
   - Product cards must show image quality, price, seller confidence, condition/category, rating/review summary, delivery readiness, favorite state, and clear tap targets.
   - Product detail must prioritize image gallery, price, seller card, delivery/payment trust, reviews, report/share/favorite actions, and sticky add-to-cart/chat actions.

3. **Cart, Checkout, Paymob Result, Orders**
   - Cart and checkout should read like a checkout flow: item summary, delivery address, payment method, fees, Paymob confirmation, and risk/error states.
   - Order list/detail should show timeline, seller/buyer context, payment status, fulfillment status, and support actions.

4. **Seller, Chat, Notifications, Profile**
   - Seller center should expose inventory health, order queue, promotion entry points, storefront preview, and bulk tools.
   - Chat should emphasize product context and safe transaction cues.
   - Notifications/profile/settings should have polished empty/loading/error states and consistent navigation.

### Public App Acceptance

- No admin routes or admin affordances return to the public app.
- Public UI uses shared tokens/widgets, not one-off screen styling.
- Tests cover home/product/card/detail/cart/checkout/orders/seller/chat/profile states plus Arabic/RTL regressions.
- Web, mobile, and APK build gates remain green.

## Admin Web: Security Console

### Visual Language

- Use `AdminColors`, `AdminSpacing`, `AdminRadius`, `AdminScaffold`, `AdminDataGrid`, `AdminDetailDrawer`, `AdminStatusBadge`, and callable command services.
- Keep the console operational and evidence-first: tables, filters, action bars, detail panels, status badges, audit context, capped queries, and role-aware actions.
- Use restrained color: status colors should communicate risk and state, not decoration.
- Admin UI hiding is never the security boundary. Firestore Rules, Storage Rules, Custom Claims, callable commands, and audit logs remain authoritative.

### Screen Plan

1. **Operations Dashboard**
   - Add operational summary cards for moderation backlog, merchant verification, payment anomalies, reports, risk queue, and audit activity.
   - Add direct links into filtered work queues.

2. **Moderation and Merchant Evidence**
   - Product moderation and merchant verification screens must show photo/document evidence, document metadata, status, assigned/reviewer context, and reason capture.
   - Detail drawers should expose latest audit entries and immutable command history.

3. **Role-Aware Actions**
   - Every row/header action must be visible, disabled, or hidden according to role and capability.
   - Sensitive actions must launch reason/evidence dialogs and call backend commands only.

4. **Server-Side Filters and Capped Reads**
   - Replace local-only filtering with visible server-side filter controls for core tables.
   - Preserve capped/cursor query behavior and test it.

5. **Audit and Security Views**
   - Audit logs should be searchable by actor, target, action, severity, and time window.
   - Payments/Paymob operations should expose status transitions, webhook duplication handling, refund/dispute visibility, and immutable audit links.

### Admin Acceptance

- Admin stays in `apps/admin_web`; public app stays clean of admin routes.
- Admin tables use capped/cursor queries and visible server-side filters.
- Sensitive writes go through callable backend commands with reason/audit evidence.
- Role-aware action visibility and detail/audit panels have tests.
- Admin analyze/test/build gates remain green.

## Implementation Sequence

1. Create shared design contract updates for buyer widgets and admin tokens.
2. Implement Premium Marketplace home and product card/detail slice.
3. Implement cart/checkout/orders polish and Paymob result states.
4. Implement seller/chat/notifications/profile polish and Arabic/RTL tests.
5. Implement Admin Security Console dashboard, filters, action visibility, and detail/audit panels.
6. Expand emulator-backed Firestore/Storage and Paymob webhook scenario tests.
7. Run full public/admin/rules validation gates and update plan evidence.

## Figma Handoff Prompt

When the Figma plugin is available, create a design file named `Olmeg Connect - Premium Marketplace + Admin Security Console` with:

- Page 1: Public app mobile frames for Home, Product Detail, Cart/Checkout, Orders, Seller Center, Chat, Profile, Arabic RTL Home.
- Page 2: Admin web frames for Dashboard, Product Moderation, Merchant Verification, Users, Reports, Paymob Operations, Audit Logs.
- Page 3: Design tokens and component notes mapping to `AppTheme`, `Buyer*` widgets, `AdminTokens`, `AdminScaffold`, `AdminDataGrid`, and `AdminDetailDrawer`.
