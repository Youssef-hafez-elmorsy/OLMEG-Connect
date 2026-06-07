# Admin Web Console Route Structure

## Route Table

| Route | Page | Allowed Roles | Redirect When Denied |
|-------|------|---------------|----------------------|
| `/login` | Admin Login | signed-out users, expired sessions | Authorized users redirect to `/dashboard` or first allowed page |
| `/access-denied` | Access Denied | any denied user | Sign out or link back to public marketplace |
| `/dashboard` | Dashboard | admin, super_admin | `/access-denied` |
| `/users` | Users Management | admin, super_admin | `/access-denied` |
| `/moderation/products` | Product Moderation | moderator, admin, super_admin | `/access-denied` |
| `/reports` | Reports | moderator, support, admin, super_admin | `/access-denied` |
| `/merchants` | Merchant Verification | admin, super_admin | `/access-denied` |
| `/notifications` | Notifications | admin, super_admin | `/access-denied` |
| `/audit-logs` | Audit Logs | super_admin | `/access-denied` |

## Operations Console v2 Route Expansion

These routes define the target Amazon/Noon-style admin console. Implementation should be phased according to [admin-operations-v2-roadmap.md](./admin-operations-v2-roadmap.md).

| Route | Page | Allowed Roles | Redirect When Denied |
|-------|------|---------------|----------------------|
| `/search` | Global Admin Search | support, admin, super_admin | `/access-denied` |
| `/users/:userId` | User Detail | support, admin, super_admin with scoped fields | `/access-denied` |
| `/merchants/:merchantId` | Merchant Detail | admin, super_admin | `/access-denied` |
| `/catalog/products` | Product Catalog | moderator, admin, super_admin | `/access-denied` |
| `/catalog/products/:productId` | Product Detail | moderator, admin, super_admin | `/access-denied` |
| `/catalog/categories` | Category Management | admin, super_admin | `/access-denied` |
| `/moderation/reviews` | Review Moderation | moderator, admin, super_admin | `/access-denied` |
| `/reports/:reportId` | Report Detail | moderator, support, admin, super_admin | `/access-denied` |
| `/orders` | Orders Operations | support, admin, super_admin | `/access-denied` |
| `/orders/:orderId` | Order Detail | support, admin, super_admin | `/access-denied` |
| `/payments` | Payment Operations | admin, super_admin | `/access-denied` |
| `/refunds` | Refund and Return Operations | support, admin, super_admin | `/access-denied` |
| `/support/tickets` | Support Tickets | support, admin, super_admin | `/access-denied` |
| `/marketing/notifications` | Notification Campaigns | admin, super_admin | `/access-denied` |
| `/marketing/promotions` | Promotions and Coupons | admin, super_admin | `/access-denied` |
| `/risk` | Risk Dashboard | admin, super_admin | `/access-denied` |
| `/analytics` | Marketplace Analytics | admin, super_admin | `/access-denied` |
| `/staff` | Staff and Role Management | super_admin | `/access-denied` |
| `/settings` | Operations Settings | super_admin | `/access-denied` |

## Role Matrix

| Capability | moderator | support | admin | super_admin |
|------------|-----------|---------|-------|-------------|
| Dashboard | No | No | Yes | Yes |
| Users Management | No | Limited read only if needed for reports | Yes | Yes |
| Product Moderation | Yes | No | Yes | Yes |
| Reports | Yes | Yes | Yes | Yes |
| Merchant Verification | No | No | Yes | Yes |
| Notifications | No | No | Yes | Yes |
| Audit Logs | No | No | No | Yes |
| Role Assignment | No | No | No | Yes |
| Global Search | No | Scoped | Yes | Yes |
| User Detail | No | Scoped support fields | Yes | Yes |
| Orders | No | Support scope | Yes | Yes |
| Payments | No | No | Yes | Yes |
| Refunds/Returns | No | Support scope | Yes | Yes |
| Support Tickets | No | Yes | Yes | Yes |
| Catalog Management | Read/moderate products only | No | Yes | Yes |
| Marketing Campaigns | No | No | Yes | Yes |
| Risk Dashboard | No | No | Yes | Yes |
| Staff Management | No | No | No | Yes |

## Routing Rules

- All protected routes must wait for auth state and role validation before rendering page content.
- Admin routes must not request protected Firestore data before role validation succeeds.
- Non-admin users must see `/access-denied` and be signed out or redirected to the public marketplace.
- Unknown admin routes should redirect to the first route allowed for the current role, or `/access-denied` if no role is valid.
- Route guards must be mirrored by Firestore Rules; route guards alone are not security.
- Sensitive v2 route actions must call trusted backend commands; UI buttons and route checks are never the security boundary.
- Detail routes must load only role-allowed fields and linked context.
- Global search must be scoped by role and must not perform unbounded client-side scans.
