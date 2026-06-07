# Acceptance Checklist: UI/Admin/Security/Test Upgrade

## Plan Hygiene

- [X] Spec Kit feature folder exists.
- [X] `plan.md`, `spec.md`, `tasks.md`, `quickstart.md`, and checklist exist.
- [X] Agent context points to this plan.
- [X] Validation evidence is updated after each later implementation batch.

## Public App

- [X] Premium Marketplace direction is selected and documented.
- [ ] Premium home/product discovery UI is tested.
- [ ] Product card/detail UI is tested.
- [ ] Cart/checkout/orders UI is tested.
- [ ] Seller/chat/notifications/profile UI is tested.
- [ ] Arabic/RTL states are tested.

## Admin Web

- [X] Admin remains a standalone Flutter Web app.
- [X] Admin Security Console direction is selected and documented.
- [X] Product catalog supports product photos.
- [X] Product moderation supports product photos.
- [X] Admin route/RBAC tests exist.
- [X] Admin action visibility tests cover all role/action pairs.
- [ ] Detail/audit panel tests cover core operations.

## Security

- [X] Firestore deny-by-default tests exist.
- [X] Storage rule static tests exist.
- [X] Public app admin separation tests exist.
- [ ] Emulator-backed Firestore/Storage rule tests exist.
- [ ] Paymob webhook scenario tests exist.
