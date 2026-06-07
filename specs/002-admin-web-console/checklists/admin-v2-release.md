# Admin V2 Release Checklist

- [x] Every visible admin route is role-scoped in `adminRoutes`.
- [x] Dynamic detail routes are protected by the same RBAC matrix.
- [x] Operational tables use capped reads and local filtering only.
- [x] Sensitive writes go through callable backend commands.
- [x] Generic operational command actions are allowlisted.
- [x] Generic operational command fields block role/custom-claim escalation.
- [x] Immutable audit logs are written for backend commands.
- [x] Admin-only collections are excluded from broad Firestore fallback rules.
- [x] Firestore indexes cover v2 queues and filters.
- [x] Admin web installs an error-reporting hook.
- [x] Smoke tests cover v2 route registration.
- [x] Security tests cover rules, command layer, indexes, and monitoring hooks.
- [x] Rollback target is Firebase Hosting `admin`, separate from `main`.
